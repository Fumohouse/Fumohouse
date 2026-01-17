# `@fumohouse/netcode`: Multiplayer networking

**Summary:** The netcode module builds on Godot's high-level multiplayer system
to support both low(er)-level packets and the RPC system.

1. The networking system uses Godot's high-level multiplayer system to maintain
   support for RPCs.
1. Communication currently uses WebSockets due to [lack of Godot support for
   ENet DTLS](https://github.com/godotengine/godot-proposals/issues/10627). UDP
   support via ENet is planned.
1. Critical components will use lower-level binary packets. Less important
   components can use RPCs or packets, depending on convenience.
1. Due to reliance on the `SceneMultiplayer` protocol, the transport-layer
   packet layout is undefined.
1. There is no limit on binary packet size; the system relies on lower levels
   of the networking stack to split large packets.
1. Godot supports sending client-to-client packets ("server relay"); this is not
   supported. All packets and RPCs must be explicitly relayed by the server.

## Packet specification

This section only covers the packet structure introduced in Fumohouse, not
`SceneMultiplayer`, WebSocket, ENet, etc.

1. The first *N* bytes (variable-length unsigned integer) indicate the size of
   the packet, including the ID but not the size itself.
1. The following *M* bytes of the packet are the packet identifier (see below).
1. The remaining bytes are packet-defined payload.
1. To avoid remote code execution, it is forbidden to send serialized objects in
   a packet.

## Packet identifiers

1. Identifiers are variable-length; high-importance packets are assigned shorter
   identifiers.
1. Bytes ranging from `0x00` to `0x7F` are terminal and indicate the end of the
   identifier.
1. Bytes ranging from `0x80` to `0xFF` indicate the identifier will continue in
   the next byte.

Identifier allocation:

| ID     | Server-bound/Client-origin               | Client-bound/Server-origin     |
|--------|------------------------------------------|--------------------------------|
| `0x00` | `HELLOC`: Request to join                | `HELLOS`: Handshake reply      |
| `0x01` | `GOODBYE`: Disconnect with reason        | *Same as server-bound*         |
| `0x02` | `AUTH`: Continue handshake, authenticate | `SYNC`: Sync peer status       |
| `0x03` |                                          | `PEER`: Peer status            |
| `0x04` | `PING`: Latency test                     | *Same as server-bound*         |
| `0x40` | `CHRSPAWN`: Character spawn request      | Remote character spawn         |
| `0x41` | `CHRDEL`: Character delete request       | Remote character delete        |
| `0x42` |                                          | `CHRSYN`: Character state sync |
| `0x43` | `CHRAPR`: Character appearance request   | Remote appearance change       |

Reserved for future use:

| Byte prefix    | Reserved by | Purpose                             |
|----------------|-------------|-------------------------------------|
| `0x05`--`0x7F` | Fumohouse   | First-party critical components     |
| `0xF0`--`0xF3` | Fumohouse   | First-party non-critical components |

## Networking logic

### Connection procedure

1. The client connects to the server.
1. The client sends `HELLOC` to the server.
1. The server responds with `HELLOS`, providing the required method of
   authentication.
   - The world is negotiated at this stage (logic implemented in
     `@fumohouse/world`).
1. The client acknowledges `HELLOS` with `AUTH`, providing authentication
   details if necessary.
   - The client will disconnect if it does not have the required world (logic
     implemented in `@fumohouse/world`).
1. If authentication fails, the server kicks the client. Otherwise, the server
   acknowledges the client join by sending it a `SYNC` packet containing other
   joined peers' information.

> Between each handshake step, the side expecting a response starts a countdown.
> On expiry, if the handshake has not proceeded, that side terminates the
> connection.

### Remote join and leave

- The server sends `PEER` packets whenever a peer's status updates (i.e., join
  and leave). Only clients that have finished handshake receive `PEER` packets.
  `PEER` packets are not sent to the client they are about.

### Heartbeat

Both the client and server periodically send `PING` to determine if the
connection is still alive. If the opposing side does not reply in time, the
connection times out.

### Disconnection procedure

- Disconnect without reason: The server/client terminates the connection
  immediately.
- Disconnect by server with reason: The server sends `GOODBYE` and the client
  acknowledges it by disconnecting. The server terminates the connection after a
  timeout.
- Disconnect by client with reason: The client sends `GOODBYE` and the server
  acknowledges it by disconnecting the client. The client leaves after a
  timeout.

### Server close

1. The server sends `GOODBYE` to all clients.
1. The server waits until all clients disconnect or until a fixed timeout, then
   terminates.
