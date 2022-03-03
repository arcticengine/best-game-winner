options debugger            // uncomment for debug in VS Code
require daslib/debug        // uncomment for debug in VS Code
require daslib/media

var level_text = "
########         ############       ############
# ##   ###########          #########          #
"

struct Unit 
    is_enabled : bool
    is_hero : bool
    pos : float2
    vel : float2

var units : array<Unit>

var snd_step : SoundHandle

var seed : int4

var img_hero : ImageHandle
var img_tree : ImageHandle
var hero_pos : float2
var hero_vel : float2

var floor_y = 1080.f - 10.f
var time_between_steps = 0.1f

var time_since_step : float

def add_unit(pos: float2)
    var u : Unit
    u.is_hero = false
    u.is_enabled = true
    u.pos = pos
    u.vel = float2(0.f, 0.f)
    units |> push(u)
    return

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize(is_hard_reload: bool)
    set_window_title("best game winner")
    level_text = replace(level_text,"\n","")

    set_resolution(1920, 1080)

    img_hero = create_managed_image("hero.png")
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
    add_unit(float2(1000.f, 500.f))

    return

def move_unit(var u: Unit&; dt:float)
    
    if u.pos.y < floor_y
        u.pos.y = min(floor_y, u.pos.y + u.vel.y * dt + 9.8 * dt * dt)
        u.vel.y += 150.0*9.8 * dt
    else
        if u.vel.y < 0.0
            u.pos += u.vel * dt
        else
            if u.vel.y != 0.f
                snd_step |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)
            u.pos.y = floor_y
            u.vel.y = 0.0

    u.pos.x = u.pos.x + u.vel.x * dt

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    for u in units    
        move_unit(u, dt)

    var do_step = false
    units[0].vel.x = units[0].vel.x * 0.5
    if get_key(VK_A) || get_key(VK_LEFT)
        units[0].vel.x = -150.0*5.0
        do_step = units[0].vel.y == 0.f
    if get_key(VK_D) || get_key(VK_RIGHT)
        units[0].vel.x = 150.0*5.0
        do_step = units[0].vel.y == 0.f
    if get_key(VK_W) || get_key(VK_UP)
        if units[0].pos.y >= floor_y
            units[0].vel.y = -150.0*9.8

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
    set_font_size(12)
    var text = "Controls: WAD"
    text_out(get_screen_width()/2 - int(get_text_size(text).x)/2, get_screen_height()-15, text, make_color32(255,255,255))

    enable_alpha_blend()

    for u in units
        var img = u.is_hero ? img_hero : img_tree
        img |> draw_image(u.pos.x, u.pos.y - float(img.height))

    img_hero |> draw_image(hero_pos.x, hero_pos.y - float(img_hero.height))

    return
