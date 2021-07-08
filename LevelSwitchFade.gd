extends CanvasLayer

signal anim_finished

onready var col_rect = $ColorRect
onready var shader : ShaderMaterial = col_rect.material

var character_node : Node2D
var character_camera : Camera2D

func _ready() -> void:
	_on_ColorRect_resized()
	start_fade_back()
	set_process(false)

func _process(_delta: float) -> void:
	_update_character_position_on_screen()

func set_character(character : Node2D):
	character_node = character
	character_camera = character_node.get_node("Camera2D")

func _update_character_position_on_screen():
	if character_node and character_camera:
		shader.set_shader_param("CenterPosition", (character_node.global_position - character_camera.get_camera_screen_center()) / character_camera.zoom)

func start_fade():
	$FadeAnim.play("Fade")

func start_fade_back():
	$FadeAnim.play_backwards("Fade")

func _on_FadeAnim_animation_finished(_anim_name: String) -> void:
	emit_signal("anim_finished")
	character_node = null
	character_camera = null

func set_rect_size(rect_size : Vector2):
	shader.set_shader_param("RectSize", rect_size)

func _on_ColorRect_resized() -> void:
	if col_rect:
		set_rect_size(col_rect.rect_size)
