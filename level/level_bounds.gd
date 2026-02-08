extends StaticBody2D

func _ready() -> void:
    %LeftWall.shape.size.y = get_viewport_rect().size.y
    %LeftWall.global_position.y = get_viewport_rect().size.y / 2
    %LeftWall.global_position.x = -%LeftWall.shape.size.x / 2

    %RightWall.shape.size.y = get_viewport_rect().size.y
    %RightWall.global_position.y = get_viewport_rect().size.y / 2
    %RightWall.global_position.x = get_viewport_rect().size.x + %RightWall.shape.size.x / 2

    %TopWall.shape.size.x = get_viewport_rect().size.x
    %TopWall.global_position.x = get_viewport_rect().size.x / 2
    %TopWall.global_position.y = -%TopWall.shape.size.y / 2
