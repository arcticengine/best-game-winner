options debugger            // uncomment for debug in VS Code
require daslib/debug        // uncomment for debug in VS Code
require daslib/media
require map

var level_text = "
########         ############       ############
# ##   ###########          #########          #
"

struct Unit
    is_enabled : bool
    is_hero : bool
    is_face_right : bool
    is_lie : bool
    is_vertical_slowdown : bool
    pos : float2
    vel : float2
    frame_count : int
    frame_idx : int
    time_in_cur_frame : float

struct Bullet
    is_enabled : bool
    is_heroes : bool
    pos : float2
    vel : float2

var units : array<Unit>
var bullets : array<Bullet>

var snd_step : SoundHandle

var seed : int4

var img_hero_idle_l : ImageHandle
var img_hero_idle_r : ImageHandle
var img_hero_jump_l : ImageHandle
var img_hero_jump_r : ImageHandle
var img_hero_walk_l : ImageHandle
var img_hero_walk_r : ImageHandle
var img_hero_lie_l : ImageHandle
var img_hero_lie_r : ImageHandle

var img_tree : ImageHandle
var hero_pos : float2
var hero_vel : float2

var floor_y = 1080.f - 10.f
var time_between_steps = 0.1f

var time_since_step : float

var is_prev_trigger_pressed : bool

def add_unit(pos: float2)
    var u : Unit
    u.is_hero = false
    u.is_enabled = true
    u.is_face_right = true
    u.is_lie = false
    u.is_vertical_slowdown = false
    u.pos = pos
    u.vel = float2(0.f, 0.f)
    u.frame_count = 1
    u.frame_idx = 0
    u.time_in_cur_frame = 0.f
    units |> push(u)
    return

def add_bullet(is_heroes: bool; pos: float2; vel: float2)
    var b : Bullet
    b.is_enabled = true
    b.is_heroes = is_heroes
    b.pos = pos
    b.vel = vel
    bullets |> push(b)
    return

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize(is_hard_reload: bool)
    set_window_title("best game winner")
    level_text = replace(level_text,"\n","")

    set_resolution(1920, 1080)

    img_hero_idle_l = create_managed_image("hero_idle_l.png")
    img_hero_idle_r = create_managed_image("hero_idle_r.png")
    img_hero_jump_l = create_managed_image("hero_jump_l.png")
    img_hero_jump_r = create_managed_image("hero_jump_r.png")
    img_hero_walk_l = create_managed_image("hero_walk_l.png")
    img_hero_walk_r = create_managed_image("hero_walk_r.png")
    img_hero_lie_l = create_managed_image("hero_lie_l.png")
    img_hero_lie_r = create_managed_image("hero_lie_r.png")

    img_tree = create_managed_image("tree.png")
    
    time_since_step = 0.f

    var wav : array<float>
    randomize_seed(seed)
    var dur = 441
    wav |> push(0.f)
    for t in range(1,dur)
        wav |> push(random_float(seed) * float(dur - t) / float(dur)* 0.1f)
    for t in range(1,dur)
        wav[t] = (wav[t] + wav[t-1]) / 2.f

    snd_step = create_managed_sound(44100, wav)

    add_unit(float2(500.f, 500.f))
    units[0].is_hero = true;
    units[0].frame_count = 3;
    add_unit(float2(1000.f, 500.f))

    is_prev_trigger_pressed = false

    return

def move_unit(var u: Unit&; dt:float)
    
    if u.pos.y < floor_y
        u.pos.y = min(floor_y, u.pos.y + u.vel.y * dt + 9.8 * dt * dt)
        if u.is_vertical_slowdown && u.vel.y < 0.f
            u.vel.y += 150.0*9.8 * dt * 2.f
        else
            u.vel.y += 150.0*9.8 * dt
    else
        if u.vel.y < 0.0
            u.pos += u.vel * dt
        else
            if u.vel.y != 0.f
                snd_step |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)
            u.pos.y = floor_y
            u.vel.y = 0.f

    u.pos.x = u.pos.x + u.vel.x * dt


// use animation state machine and functions to control it
// enum HeroAnimationStates
//     idle
//     run
//     jump
// def start_hero_idle_animation()
// def start_hero_run_animation()
// def start_hero_jump_animation()

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    var shoot_dir = float2(0.f, 0.f)
    var do_step = false
    units[0].vel.x = units[0].vel.x * 0.5
    if abs(units[0].vel.x) < 100.f
        units[0].vel.x = 0.f
    var do_lie = false
    if get_key(VK_A) || get_key(VK_LEFT)
        shoot_dir.x = -1.f
        units[0].vel.x = -150.0*5.0
        units[0].is_face_right = false
        do_step = units[0].vel.y == 0.f
    if get_key(VK_D) || get_key(VK_RIGHT)
        shoot_dir.x = 1.f
        units[0].vel.x = 150.0*5.0
        units[0].is_face_right = true
        do_step = units[0].vel.y == 0.f
    if get_key(VK_W) || get_key(VK_UP)
        shoot_dir.y = -1.f
    if get_key(VK_S) || get_key(VK_DOWN)
        print("s")
        if units[0].vel.x == 0.f && units[0].vel.y == 0.f
            print("x")
            do_lie = true
        else
            shoot_dir.y = 1.f
    
    units[0].is_lie = do_lie

    if get_key(VK_M)
        if units[0].pos.y >= floor_y
            units[0].vel.y = -150.0*9.8
            units[0].is_vertical_slowdown = false
    else
        units[0].is_vertical_slowdown = true

    if shoot_dir.x == 0.f && shoot_dir.y == 0.f
        shoot_dir.x = 1.f
    shoot_dir = normalize(shoot_dir)

    if get_key(VK_N)
        if !is_prev_trigger_pressed
            is_prev_trigger_pressed = true
            var bullet_vel = 1500.f * shoot_dir
            var start_pos = units[0].pos + float2(48.f, -150.f)
            if units[0].is_lie
                start_pos += float2(150.f, 70.f)
            add_bullet(true, start_pos, bullet_vel + float2(units[0].vel.x, 0.f))
    else
        is_prev_trigger_pressed = false

    for u in units    
        move_unit(u, dt)
        u.time_in_cur_frame += dt
        if u.time_in_cur_frame >= frame_duration
            u.time_in_cur_frame = 0.f
            u.frame_idx = (u.frame_idx + 1) % u.frame_count

    var screen_size = float2(float(get_screen_width()), float(get_screen_height()))
    
    var i : int = int(length(bullets))  - 1
    while i >= 0
        bullets[i].pos += bullets[i].vel * dt
        var do_remove = false
        if bullets[i].is_heroes
            var unit_idx = 0
            while unit_idx < length(units)
                var u = units[unit_idx]
                // todo: collisions with enemies
                unit_idx++
        else
            // todo: collisions with the hero
            var u = units[0]

        if bullets[i].pos.x > screen_size.x && bullets[i].vel.x > 0.f
            do_remove = true
        elif bullets[i].pos.y > screen_size.y && bullets[i].vel.y > 0.f
            do_remove = true
        elif bullets[i].pos.x < 0.f && bullets[i].vel.x < 0.f
            do_remove = true
        elif bullets[i].pos.y < 0.f && bullets[i].vel.y < 0.f
            do_remove = true
        if do_remove
            bullets[i] = bullets[length(bullets) - 1]
            pop(bullets)
        i--

    time_since_step += dt
    if do_step && time_since_step >= time_between_steps
        snd_step |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)
        time_since_step = 0.f

    var remaining_dt = dt
    return

// this function will be called every frame after 'act',
// you can draw anything in this function
var hero_frame_count = 2
var frame_duration = 1.f / 15.f
[export]
def draw
    set_font_size(48)
    var text = "Controls: WSAD NM"
    text_out(get_screen_width()/2 - int(get_text_size(text).x)/2, get_screen_height()-60, text, make_color32(255,255,255))

    enable_alpha_blend()

    for u in units
        if u.is_hero
            var frame_width = 122
            var frame_height = 256
            var vertical_num = 1
            let rect = float4(float(frame_width*u.frame_idx),
                            float(0),
                            float(frame_width),
                            float(frame_height))
        
            var img = u.is_face_right ? img_hero_idle_r : img_hero_idle_l
            if u.is_lie && u.vel.y == 0.f && u.vel.x == 0.f
                img = u.is_face_right ? img_hero_lie_r : img_hero_lie_l
                img |> draw_image(u.pos.x, u.pos.y - float(img.height))
            elif (u.vel.y != 0.f)
                img = u.is_face_right ? img_hero_jump_r :img_hero_jump_l
                img |> draw_image_region(u.pos.x, u.pos.y - float(img.height), rect)
            elif (u.vel.y == 0.f && u.vel.x != 0.f)
                img = u.is_face_right ? img_hero_walk_r : img_hero_walk_l
                img |> draw_image_region(u.pos.x, u.pos.y - float(img.height), rect)
            else
                img |> draw_image_region(u.pos.x, u.pos.y - float(img.height), rect)
        else
            var img = img_tree
            img |> draw_image(u.pos.x, u.pos.y - float(img.height))

    for b in bullets
        if b.is_enabled
            fill_circle(b.pos.x, b.pos.y, 10.f, make_color32(255,32,32))
            fill_circle(b.pos.x, b.pos.y, 7.f, make_color32(32,32,255))
    return
