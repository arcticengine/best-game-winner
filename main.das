options debugger            // uncomment for debug in VS Code
require daslib/debug        // uncomment for debug in VS Code
require daslib/media
require math
require map

///////////////////////////////////////////////////////////////////////////////
//  TYPES
///////////////////////////////////////////////////////////////////////////////
struct Unit
    is_enabled : bool
    is_hero : bool
    is_face_right : bool
    is_lie : bool
    is_vertical_slowdown : bool
    is_on_the_ground : bool
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

struct LevelCell
    is_walkable : bool
    is_down_jump_allowed : bool
    is_up_jump_allowed : bool
    is_empty : bool

///////////////////////////////////////////////////////////////////////////////
//  SETTINGS
///////////////////////////////////////////////////////////////////////////////
var time_between_steps = 0.1f
var frame_duration = 1.f / 15.f

var level_text = "
E#               ####   #####  EE E #####   ####
#              E   E EEE    #########E EE      #
      E        ##  ######    EE EE ###### E    #
    #### EE     E E     E   #######     E## E  #
#        ## EE ####  E  # EE E   ## EE  # # # E#
"

///////////////////////////////////////////////////////////////////////////////
//  VARIABLES
///////////////////////////////////////////////////////////////////////////////
var units : array<Unit>
var bullets : array<Bullet>
var level : array<LevelCell>

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

var img_bg : ImageHandle

var floor_y = 1080.f - 10.f
var time_since_step : float
var is_prev_trigger_pressed : bool

var level_view_pos : float2

///////////////////////////////////////////////////////////////////////////////
//  CODE
///////////////////////////////////////////////////////////////////////////////
def add_unit(pos: float2)
    var u : Unit
    u.is_hero = false
    u.is_enabled = true
    u.is_face_right = true
    u.is_lie = false
    u.is_vertical_slowdown = false
    u.is_on_the_ground = false
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

def at(p:int2): int
    return p.x+p.y*48

def level_at(pos:int2) : LevelCell
    if pos.x < 0 || pos.x >= 48 || pos.y < 0 || pos.y >=5
        var c : LevelCell
        c.is_walkable = false
        c.is_down_jump_allowed = true
        c.is_up_jump_allowed = true
        c.is_empty = true
        return c
    return level[at(pos)]

def space_to_level(p:float2): int2
    var offset_p = p - float2(0.f, 80.f)
    var cell_p = offset_p / 200.f
    var int_p = int2(int(cell_p.x), int(ceil(cell_p.y)))
    return int_p

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize(is_hard_reload: bool)
    set_window_title("best game winner")

    add_unit(float2(100.f, 500.f))
    units[0].is_hero = true;
    units[0].frame_count = 3;
    
    level_text = replace(level_text,"\n","")
    for y in range(0,5)
        for x in range(0,48)
            var c : int
            c = character_at(level_text, x+y*48)
            var cell : LevelCell
            cell.is_walkable = c=='#'
            cell.is_down_jump_allowed = c=='#'
            cell.is_up_jump_allowed = c=='#'
            cell.is_empty = c!='#'
            level |> push(cell)
            if c=='E'
                add_unit(float2(float(x) * 200.f + 100.f, 80.f + float(y) * 200.f))

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
    
    img_bg = create_managed_image("bg.jpg")

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

    

    is_prev_trigger_pressed = false
    level_view_pos = float2(0.f, 0.f)
    return

def get_floor_for(pos: float2)
    var level_pos = space_to_level(pos)
    var cell = level_at(level_pos)

    var cur_floor_y = floor_y;
    if pos.y == float(level_pos.y) * 200.0 + 80.f && cell.is_walkable
        return pos.y
    var y = level_pos.y
    while y < 5
        if level_at(int2(level_pos.x, y)).is_walkable
            return float(y) * 200.0 + 80.f
        y++
    return floor_y

def move_unit(var u: Unit&; dt:float)
    var prev_pos = u.pos
    var prev_level_pos = space_to_level(u.pos)
    var prev_cell = level_at(prev_level_pos)

    var cur_floor_y = get_floor_for(u.pos)
    
    if u.pos.y < cur_floor_y
        u.pos.y = min(cur_floor_y, u.pos.y + u.vel.y * dt + 9.8 * dt * dt)
        if u.is_vertical_slowdown && u.vel.y < 0.f
            u.vel.y += 150.0*9.8 * dt * 2.f
            u.is_on_the_ground = false
        else
            u.vel.y += 150.0*9.8 * dt
            u.is_on_the_ground = false
    else
        if u.vel.y < 0.0
            u.pos += u.vel * dt
            u.is_on_the_ground = false
        else
            if u.vel.y != 0.f
                snd_step |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)
            u.is_on_the_ground = true
            u.pos.y = cur_floor_y
            u.vel.y = 0.f
    
    var new_pos = u.pos
    var new_level_pos = space_to_level(u.pos)
    var new_cell = level_at(new_level_pos)

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
        if units[0].vel.x == 0.f && units[0].vel.y == 0.f
            do_lie = true
        else
            shoot_dir.y = 1.f
    
    units[0].is_lie = do_lie

    if get_key(VK_M)
        var cur_floor_y = get_floor_for(units[0].pos)
        var is_downjump = false
        if cur_floor_y == units[0].pos.y
            if units[0].is_on_the_ground
                if get_key(VK_DOWN) || get_key(VK_S)
                    var cell = level_at(space_to_level(units[0].pos))
                    if cell.is_down_jump_allowed
                        units[0].pos.y += 1.f
                        is_downjump = true
        if units[0].pos.y >= cur_floor_y && !is_downjump
            units[0].vel.y = -150.0*9.8
            units[0].is_vertical_slowdown = false
    else
        units[0].is_vertical_slowdown = true

    if shoot_dir.x == 0.f && shoot_dir.y == 0.f
        shoot_dir = float2(units[0].is_face_right ? 1.f : -1.f, 0.f)
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

    level_view_pos = approach(level_view_pos, units[0].pos - screen_size * 0.5, dt, 0.25)
    if level_view_pos.x < 0.f
        level_view_pos.x = 0.f
    if level_view_pos.y > 0.f
        level_view_pos.y = 0.f

    var i : int = int(length(bullets))  - 1
    while i >= 0
        bullets[i].pos += bullets[i].vel * dt
        var scr_pos = bullets[i].pos - level_view_pos
        var do_remove = false
        if bullets[i].is_heroes
            var unit_idx = 1
            while unit_idx < length(units)
                var u = units[unit_idx]
                var p0 = float2(u.pos.x-float(img_tree.width)*0.5, u.pos.y - float(img_tree.height))
                var p1 = float2(u.pos.x+float(img_tree.width)*0.5, u.pos.y)
                var b_pos = bullets[i].pos
                if b_pos.x >= p0.x && b_pos.y >= p0.y && b_pos.x <= p1.x && b_pos.y <= p1.y
                    do_remove = true
                    units[unit_idx] = units[length(units) - 1]
                    pop(units)
                unit_idx++
        else
            // todo: collisions with the hero
            var u = units[0]

        if scr_pos.x > screen_size.x && bullets[i].vel.x > 0.f
            do_remove = true
        elif scr_pos.y > screen_size.y && bullets[i].vel.y > 0.f
            do_remove = true
        elif scr_pos.x < 0.f && bullets[i].vel.x < 0.f
            do_remove = true
        elif scr_pos.y < 0.f && bullets[i].vel.y < 0.f
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
[export]
def draw
    img_bg |> draw_image(0.f, 0.f)

    for x in range(0,48)
        for y in range(0,5)
            if !level[at(int2(x,y))].is_empty
                
                fill_rect(
                    float(x) * 200.f - level_view_pos.x,
                    80.f + float(y) * 200.f - level_view_pos.y,
                    200.f, 200.f, make_color32(0,128,0))
                fill_rect(
                    float(x) * 200.f - level_view_pos.x,
                    80.f + 20.f + float(y) * 200.f - level_view_pos.y,
                    200.f, 180.f, make_color32(128,68,0))

    set_font_size(48)
    var text = "Controls: WSAD NM"
    text_out(get_screen_width()/2 - int(get_text_size(text).x)/2, get_screen_height()-60, text, make_color32(255,255,255))

    enable_alpha_blend()

    for u in units
        var scr_pos = u.pos - level_view_pos
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
                img |> draw_image(scr_pos.x - float(frame_width)*0.5, scr_pos.y - float(img.height))
            elif (u.vel.y != 0.f)
                img = u.is_face_right ? img_hero_jump_r :img_hero_jump_l
                img |> draw_image_region(scr_pos.x- float(frame_width)*0.5, scr_pos.y - float(img.height), rect)
            elif (u.vel.y == 0.f && u.vel.x != 0.f)
                img = u.is_face_right ? img_hero_walk_r : img_hero_walk_l
                img |> draw_image_region(scr_pos.x- float(frame_width)*0.5, scr_pos.y - float(img.height), rect)
            else
                img |> draw_image_region(scr_pos.x- float(frame_width)*0.5, scr_pos.y - float(img.height), rect)
        else
            var img = img_tree
            img |> draw_image(scr_pos.x - float(img.width) * 0.5, scr_pos.y - float(img.height))

    for b in bullets
        if b.is_enabled
            var scr_pos = b.pos - level_view_pos
            fill_circle(scr_pos.x, scr_pos.y, 10.f, make_color32(255,32,32))
            fill_circle(scr_pos.x, scr_pos.y, 7.f, make_color32(255,128,128))
    return
