extends Area2D


export var movement_distance = 100
export var beat_actions = [[0], [2], [0], [2]]
export var beats_per_minute = 120.0
export (float, 0, 0.5) var early_leniency = 0.3
export (float, 0, 0.5) var late_leniency = 0.3

var elapsed_time = 0
var current_beat = beat_actions.size() - 1
var buffered_input = false

onready var tween = get_node("Tween")


func short_angle_dist(from, to):
    from = deg2rad(from)
    to = deg2rad(to)
    var max_angle = PI * 2
    var difference = fmod(to - from, max_angle)
    return rad2deg(fmod(2 * difference, max_angle) - difference)


func advance_beat():
    if buffered_input:
        buffered_input = false
        move(beat_actions[(current_beat + 1) % beat_actions.size()], 50)


    if current_beat == beat_actions.size() - 1:
        current_beat = 0
        $Metronome.stream = preload("res://Assets/Audio/metronomehi.ogg")
        $Metronome.play()
    else:
        current_beat += 1
        if beat_actions[current_beat]:
            $Metronome.stream = preload("res://Assets/Audio/metronomelow.ogg")
            $Metronome.play()
    if not $Music.playing:
        $Music.play()

    rotation_degrees = fmod(rotation_degrees, 360)
    for action in beat_actions[current_beat]:
        if action in range(0, 4):
            tween.interpolate_property(
                self, "rotation_degrees", rotation_degrees,
                rotation_degrees + short_angle_dist(rotation_degrees, action * 90),
                15 / beats_per_minute, Tween.TRANS_CIRC, Tween.EASE_OUT
            )
            tween.start()


func move(actions, distance):
    for action in actions:
        match action:
            0:
                tween.interpolate_property(
                    self, "position:y",
                    position.y, position.y - distance,
                    (0.8 - elapsed_time) / (beats_per_minute / 60),
                    Tween.TRANS_CIRC, Tween.EASE_OUT
                )
            1:
                tween.interpolate_property(
                    self, "position:x",
                    position.x, position.x + distance,
                    (0.8 - elapsed_time) / (beats_per_minute / 60),
                    Tween.TRANS_CIRC, Tween.EASE_OUT
                )
            2:
                tween.interpolate_property(
                    self, "position:y",
                    position.y, position.y + distance,
                    (0.8 - elapsed_time) / (beats_per_minute / 60),
                    Tween.TRANS_CIRC, Tween.EASE_OUT
                )
            3:
                tween.interpolate_property(
                    self, "position:x",
                    position.x, position.x - distance,
                    (0.8 - elapsed_time) / (beats_per_minute / 60),
                    Tween.TRANS_CIRC, Tween.EASE_OUT
                )
        tween.start()


# Called when the node enters the scene tree for the first time.
func _ready():
    $AnimatedSprite.speed_scale = beats_per_minute / 60
    $AnimatedSprite.play()
    $Music.stream = preload("res://Assets/Audio/music.ogg")


# Called whenever user input is detected.
func _input(event):
    if event.is_pressed() and not event.is_echo():
        var beat_position = elapsed_time * (beats_per_minute / 60)

        if beat_position >= 1 - early_leniency:
            buffered_input = true
        elif beat_position <= late_leniency:
            move(beat_actions[current_beat], 50)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    elapsed_time += delta
    if elapsed_time >= 1 / (beats_per_minute / 60):
        advance_beat()
        elapsed_time -= 1 / (beats_per_minute / 60)
