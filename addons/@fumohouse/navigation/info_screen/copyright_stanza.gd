extends Control

## Fired when license button is clicked.
signal license_pressed

## Copyright stanza to display.
var stanza: CopyrightFile.CopyrightFiles


func _ready():
	var comment_split := stanza.comment.split("\n")
	%Label.text = comment_split[0]
	%Files.text = "\n".join(stanza.files)
	%Copyright.text = "\n".join(stanza.copyright)
	%LicenseButton.text = stanza.license
	%LicenseButton.pressed.connect(license_pressed.emit)

	var extended_comment: String = "\n".join(comment_split.slice(1)).strip_edges()
	if extended_comment.is_empty():
		%ExtendedComment.visible = false
	else:
		%ExtendedComment.text = extended_comment
