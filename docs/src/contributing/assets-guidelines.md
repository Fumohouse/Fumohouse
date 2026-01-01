# Guidelines for Assets

Make sure you have read the [common guidelines](./common-guidelines.md) first.

## Third-party copyright

As a fangame, Fumohouse includes third-party copyrighted material (e.g.,
characters from other games). This material may only be used if you and
Fumohouse have permission from their rightsholder. Typically, this is provided
through a derivative works guidelines document. If you plan to seek permission
to use third-party content, please coordinate with us.

Properties currently approved for use:

| Rightsholder | Property | Guidelines |
|:-|:-|:-|
| Team Shanghai Alice | Touhou Project | [JP](https://touhou-project.news/guideline/), [EN](https://touhou-project.news/guidelines_en/), [other](https://en.touhouwiki.net/wiki/Touhou_Wiki:Copyrights#Copyright_status/Terms_of_Use_of_the_Touhou_Project) |
| CAPCOM | * (Ace Attorney, Devil May Cry, etc.) | [JP](https://www.capcom-games.com/ja-jp/fan-content-guidelines/), [EN](https://www.capcom-games.com/en/fan-content-guidelines/) |
| COVER | Hololive | [JP](https://hololivepro.com/terms/), [EN](https://hololivepro.com/en/terms/) |
| Crypton Future Media | Piapro Characters (Hatsune Miku, etc.) | [JP (summary)](https://piapro.jp/license/pcl/summary), [JP (full)](https://piapro.jp/license/character_guideline) |
| Cygames | Umamusume: Pretty Derby | [JP](https://umamusume.jp/derivativework_guidelines/), [EN](https://umamusume.com/fan-createdguide/) |
| miHoYo | Genshin Impact (Global) | [EN](https://www.hoyolab.com/article/381519) |
| miHoYo | Honkai: Star Rail (Global) | [EN](https://hsr.hoyoverse.com/en-us/news/111203) |
| miHoYo | Honkai Impact 3rd (Global) | [EN](https://www.hoyolab.com/article/1463874) |
| Nexon | * (Blue Archive, etc.) | [EN](https://playersupport.nexon.com/hc/en-us/articles/360059079812-Nexon-Game-IP-Guide-for-Content-Creators) |
| Project Moon | * (Lobotomy Corporation, Limbus Company, etc.) | [EN (Twitter)](https://xcancel.com/ProjMoonStudio/status/1629085462236397573) |
| SEGA | Project Sekai: Colorful Stage! | [JP](https://pjsekai.sega.jp/guideline/index.html) |
| Yostar | Arknights | [JP](https://www.arknights.jp/fankit/guidelines), [EN](https://arknights.global/fankit/guidelines) |

These guidelines place the following important restrictions on assets (among
others that should be self-evident):

* No commercial use (i.e., by a company)
* No for-revenue use (i.e., cannot make money)
* No political or religious messaging
* No depictions of drugs or alcohol use

> **Warning**
>
> Most of these third-party usage guidelines are rather informal and subject to
> change at any time. If this happens and Fumohouse’s use is no longer
> acceptable (unlikely but possible), it may result in the removal of existing
> assets.

> **Non-free guidelines**
>
> These third-party restrictions mean that some of Fumohouse's content is not
> strictly open-source. We understand this and aim to make Fumohouse "as
> open-source as possible" rather than not use these properties. This is
> reflected in our licensing requirements (see below).

### Original characters and content

If you plan to use original characters (OC) or content in your contribution, you
must provide Fumohouse permission to use it under acceptable terms. Please
coordinate with us.

## License

Asset submissions are required to use an open-source-friendly Creative Commons
(CC) license. You must choose one of the options below (these descriptions are
not legal advice):

* [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en)
  (Attribution ShareAlike): Anyone can use your contribution if they attribute
  you and use the same or a compatible license for derivative works.
* [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.en)
  (Attribution): Anyone can use your contribution if they attribute you.
* [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/deed.en) (Public
  Domain): Anyone can use your contribution without attributing you.

Note that CC licenses cannot be revoked, all open-source-compatible CC licenses
permit commercial use, and that your license selection must be compatible with
any external assets or existing Fumohouse assets used in your submission.

> **Non-free, including NonCommercial, licenses**
>
> We do not currently allow placing additional non-free restrictions on your
> submission (e.g., through CC NonCommercial licenses) in order to be "as
> open-source as possible" (see above) and to avoid complications with the rest
> of Fumohouse's assets and contributions. If you are strongly in favor of using
> a NonCommercial license, please reach out to us for further guidance.

> **Third-party copyrights**
>
> Our interpretation (this is not legal advice) is that your chosen CC license
> applies to your unique contribution and not any third-party rights (e.g.,
> character copyright). Under this interpretation, the CC license allows full
> (e.g., commercial) use if not used to represent a third-party copyrighted work
> (e.g., if parts of a character but not a substantial, copyrighted portion is
> used, then character copyright does not apply). Otherwise, *both* third-party
> copyright restrictions and the CC license apply. This distinction is mostly
> important for downstream users of Fumohouse assets.

## Your copyright

You retain the copyright over your work unless it is released into the public
domain. Fumohouse does not claim copyright over your work; it only uses it under
the provided license.

## Copyright declaration

If you use any outside works in your submission, including those in the public
domain, you must declare it in your submission documentation. You must not
infringe others' copyright in your submission. If you believe your usage to be
fair use, please note it in your declaration.

## Credit

By default, we will credit your contribution as long as it is in the game. You
may request not to be credited or to be credited under a pen name, which will
also be used for copyright purposes.

## Retraction by you

If you wish to have your contribution removed, let us know and we will do so on
a *best effort* basis. It may not be possible to remove your contribution in a
timely manner, or at all. Even after removal, your contribution will remain in
publicly available Git history permanently, and the CC license still applies.

## Retraction by us

We avoid removing contributions as much as possible. However, it may be
necessary to do so in the following situations:

- If there were serious errors in your submission
- If you commit a severe rule violation
- If a rightsholder revokes the license to use the content you submitted

## Conventions

1. Make your submission contents easy to update by using non-destructive
   operations or making copies when this is not possible. For example, in
   Blender, convert paths to objects and apply modifiers only on copies of the
   originals.
1. For duplicated meshes, try to avoid duplicate mesh data and facilitate mesh
   reuse by exporting the duplicated mesh only once and creating its instances
   in Godot.
1. Optimize SVG graphics with `svgo --multipass`.

## Continue...

- [If you are submitting a character model](./character-guidelines.md)
- If you are submitting any other kind of asset, please coordinate with us.
- [If you are also submitting code](./code-guidelines.md)
