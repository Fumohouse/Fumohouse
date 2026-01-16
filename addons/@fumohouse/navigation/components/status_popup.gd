extends Control

var heading_text: String:
	get:
		return %Heading.text
	set(value):
		%Heading.text = value

var details_text: String:
	get:
		return %Details.text
	set(value):
		%Details.text = value
