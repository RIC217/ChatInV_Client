module utils

import net
import ui
import ui.component as uic
import gx
import libsodium

[heap]
pub struct App {
	pub mut:
	private_key libsodium.PrivateKey
	session_key []u8
	//login win
	window &ui.Window
	username_textbox &ui.TextBox
	pseudo_text string
	pseudo_is_error bool
	password_text string
	password_is_error bool
	socket &net.TcpConn
	addr string
	addr_placeholder string
	port string
	port_placeholder string

	//chat win
	messages_box &ui.TextBox
	messages_box_text string
	send_message_textbox &ui.TextBox
	send_message_textbox_text string

	mode Mode
	confirm_password_text string
	confirm_password_is_error bool
}

pub enum Mode {
	login
	register
}

pub fn (mut app App) init(win &ui.Window) {
	uic.hideable_show(win, "hform")
}

pub fn (mut app App) build_login_window() &ui.Stack {
	app.username_textbox = ui.textbox(
		placeholder: "Username"
		on_change: app.pseudo_changed
		is_error: &app.pseudo_is_error
		on_enter: app.login_or_register_textbox
	)
	return uic.hideable_stack(
		id: "hform",
		layout: ui.column(
			alignment: .center
			widths: ui.stretch
			spacing: 16
			children: [
				ui.label(
					id: "form_title"
					text: "Login"
					text_color: gx.rgb(255, 255, 255)
					justify: ui.center
					text_size: 22
				)

				app.username_textbox

				ui.textbox(
					placeholder: "Password"
					on_change: app.password_changed
					is_error: &app.password_is_error
					is_password: true
					on_enter: app.login_or_register_textbox
				)

				uic.hideable_stack(
					id: "confirm_password_textbox"
					hidden: true
					layout: ui.column(
						children: [
							ui.textbox(
								on_change: app.confirm_password_changed
								on_enter: app.login_or_register_textbox
								is_error: &app.confirm_password_is_error
								is_password: true
								placeholder: "Confirm password"
							)
						]
					)
				)

				ui.textbox(
					placeholder: app.addr_placeholder
					on_change: app.addr_changed
					on_enter: app.login_or_register_textbox
				)

				ui.textbox(
					placeholder: app.port_placeholder
					on_change: app.port_changed
					is_numeric: true
					on_enter: app.login_or_register_textbox
				)

				ui.row(
					widths: [ui.compact, ui.stretch, ui.compact]
					children: [
						ui.button(
							bg_color: gx.rgb(0, 0, 255)
							id: "login_button"
							text: "Login"
							on_click: app.login_button_pressed
							border_color: gx.rgb(0, 0, 10)
						)
						ui.spacing()
						ui.button(
							bg_color: gx.rgb(0, 0, 255)
							id: "register_button"
							text: "Register ?"
							on_click: app.register_button_pressed
							border_color: gx.rgb(0, 0, 10)
						)
					]
				)
			]
		)
	)
}

pub fn (mut app App) register_button_pressed(it &ui.Button) {
	match app.mode {
		.login {
			app.mode = .register
			app.window.get_or_panic[ui.Button]("login_button").text = "Login ?"
			app.window.get_or_panic[ui.Button]("register_button").text = "Register"
			app.window.get_or_panic[ui.Label]("form_title").text = "Register"
			app.window.set_title("Register")
			uic.hideable_show(app.window, "confirm_password_textbox")
		}
		.register {
			app.login_or_register(it)
		}
	}
}

pub fn (mut app App) login_button_pressed(it &ui.Button) {
	match app.mode {
		.login {
			app.login_or_register(it)
		}
		.register {
			app.mode = .login
			app.window.get_or_panic[ui.Button]("login_button").text = "Login"
			app.window.get_or_panic[ui.Button]("register_button").text = "Register ?"
			app.window.get_or_panic[ui.Label]("form_title").text = "Login"
			app.window.set_title("Login")
			uic.hideable_toggle(app.window, "confirm_password_textbox")
		}
	}
}

pub fn (mut app App) build_chat_app() &ui.Stack {
	app.messages_box = ui.textbox(
		text: &app.messages_box_text
		mode: .read_only | .multiline | .word_wrap
		bg_color: gx.rgb(0, 0, 0)
		text_color: gx.rgb(255, 255, 255)
	)
	app.send_message_textbox = ui.textbox(
		text: &app.send_message_textbox_text
		placeholder: "Message"
		on_enter: app.send_message
	)
	return uic.hideable_stack(
		id: "hchat",
		hidden: true
		layout: ui.column(
			heights: [ui.stretch, ui.compact]
			children: [
				app.messages_box
				app.send_message_textbox
			]
		)
	)
}