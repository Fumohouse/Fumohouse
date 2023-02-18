local Dock = gdclass(nil, Control)
	:Tool(true)

export type Dock = Control & {
	plugin: EditorPlugin,
}

return Dock
