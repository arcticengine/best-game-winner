options debugger            // uncomment for debug in VS Code
require daslib/debug        // uncomment for debug in VS Code
require daslib/media

def draw_sokoban_figure(ix,iy: float; c: uint)
    var x= ix+5.f
    var y= iy+11.f
    line(x-3.f, y, x, y-3.f, c);
    line(x+3.f, y,x, y-3.f ,c);
    line(x, y-3.f, x, y-6.f,c);
    line(x-3.f, y-5.f, x+4.f, y-5.f,c);
    circle(x, y-7.f, 1.6f, c);
    return

def draw_sokoban_wall(x,y: float; c:uint)
    line(x, y-12.f, x+10.f, y-12.f,c)
    line(x, y-9.f, x+10.f, y-9.f,c)
    line(x, y-6.f, x+10.f, y-6.f,c)
    line(x, y-3.f, x+10.f, y-3.f,c)
    line(x, y, x+10.f, y,c)

    line(x+3.f, y-9.f, x+3.f, y-12.f,c)
    line(x+8.f, y-9.f, x+8.f, y-12.f,c)

    line(x,      y-6.f, x,      y-9.f,c)
    line(x+5.f,  y-6.f, x+5.f,  y-9.f,c)
    line(x+10.f, y-6.f, x+10.f, y-9.f,c)

    line(x+2.f, y-3.f, x+2.f, y-6.f,c)
    line(x+7.f, y-3.f, x+7.f, y-6.f,c)

    line(x,      y, x,      y-3.f,c)
    line(x+5.f,  y, x+5.f,  y-3.f,c)
    line(x+10.f, y, x+10.f, y-3.f,c)
    return

def draw_box(x,y: float; c: uint)
    line(x+0.f, y- 1.f, x+9.f, y- 1.f,c)
    line(x+0.f, y- 1.f, x+0.f, y-10.f,c)
    line(x+9.f, y- 1.f, x+9.f, y-10.f,c)
    line(x+0.f, y- 1.f, x+0.f, y-10.f,c)
    line(x+0.f, y-10.f, x+9.f, y-10.f,c)
    line(x+0.f, y-10.f, x+9.f, y- 1.f,c)
    line(x+9.f, y-10.f, x+0.f, y- 1.f,c)
    return

def draw_target(x,y:float; c: uint)
    circle(x+5.f, y-6.f, 3.f, c)
    return

struct SokobanCell
    is_wall : bool
    is_box : bool
    is_target : bool
    is_visible : bool

var level : array<SokobanCell>
var sokoban_pos : int2

struct UndoFrame
    level : array<SokobanCell>
    sokoban_pos : int2

var undo_log : array<UndoFrame>

var sokoban_next_pos : int2
var sokoban_move_part : float
var sokoban_pushes : bool
var sokoban_prev_dir : int2
var time_to_undo : float

var man_vel: float
var upscale: int
var level_text = "
########         ############       ############
# ##   ###########          #########          #
#    # ## #        ###### #  #     ## ######## #
# #### #  # # ## ###    # ## # ###    # #    # #
#    # # #### #    # ##    ### # ###### ### #  #
# ####        ######  ####     #            # ##
# #  ## #######  #    ###### ### ########## #  #
# # ### #    #  ## ##      ### # #       ## ## #
# #     # ## ##       ####     #   # ### #  #  #
# #########   # ### ###  ########### #   # #####
#      #    # # #     ##       ##    # ###     #
###### ##  ## # # #####   ####    ####   # ###O#
     #    ##    #       #   #######  ### # #   #
  #### ########## # ##### ###    ## ###  # # # #
  #    #   #      # #   # ##  ##     #  ## # #O#
  # #### #### ##  #   # #    ##  # #   ##      #
### #    #  #    ###### # ##### ## #####  #### #
# # # ##### #######  ##   #   #          #   # #
# ###     #   #         # # # # ##### ##   #O# #
#   # ###   #   ##### ###           # ### ## # #
## ## # #########   ### ########  # # # ###  xx#
#     #                        #### O        xx#
#######                           ##############
"

var snd_step : SoundHandle
var snd_step_back : SoundHandle
var snd_discover : SoundHandle
var snd_done : SoundHandle
var snd_push : SoundHandle

var seed : int4

def at(p:int2): int
    return p.x+p.y*48

def push_undo()
    var frame: UndoFrame
    frame.level := level
    frame.sokoban_pos = sokoban_pos
    push_clone(undo_log, frame)

def pop_undo()
    var l = length(undo_log) - 1
    if l >= 0
        level := undo_log[l].level
        sokoban_pos = undo_log[l].sokoban_pos
        erase(undo_log, l)
        sokoban_next_pos = sokoban_pos
        sokoban_move_part = 0.f
        sokoban_prev_dir = int2(0, 0)
        sokoban_pushes = false
        snd_step_back |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)


// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize(is_hard_reload: bool)
    set_window_title("sokoban")
    level_text = replace(level_text,"\n","")

    var xupscale = get_desktop_width()/480
    var yupscale = get_desktop_height()/270
    upscale = min(xupscale,yupscale)
    set_resolution(480, 270)
    set_rendering_upscale(upscale)

    man_vel = 10.f;
    sokoban_pos = int2(1, 1)
    sokoban_next_pos = int2(1, 1)
    sokoban_move_part = 0.f
    sokoban_prev_dir = int2(0, 0)
    sokoban_pushes = false
    time_to_undo = 0.f

    for y in range(0,23)
        for x in range(0,48)
            var c : int
            c = character_at(level_text, x+y*48)
            var cell : SokobanCell
            cell.is_wall = c=='#'
            cell.is_box = c=='O'
            cell.is_target = (c=='x')
            cell.is_visible = false
            level |> push(cell)

    var wav : array<float>
    randomize_seed(seed)
    var dur = 441
    wav |> push(0.f)
    for t in range(1,dur)
        wav |> push(random_float(seed) * float(dur - t) / float(dur)* 0.1f)
    for t in range(1,dur)
        wav[t] = (wav[t] + wav[t-1]) / 2.f
    snd_step = create_managed_sound(44100, wav)

    var wav2 : array<float>
    for t in range(0,dur)
        wav2 |> push(wav[dur-t-1])
    snd_step_back = create_managed_sound(44100, wav2)
    
    for t in range(1,dur)
        wav[t] = wav[t] + random_float(seed) * 0.1f
    for t in range(1,dur*4)
        wav |> push(random_float(seed) * 0.1f)
    snd_push = create_managed_sound(44100, wav)

    var wav3 : array<float>
    dur = 44100 / 8
    var mul = 1.0594630944f
    var freq = 261.626f
    freq *= pow(mul, 24.f)
    var l = 0
    var off = 0;    
    for i in range(0, 5)
        l = length(wav3)
        for t in range(0,dur)
            var v = cos(float(t) / 44100.f * freq * 2.f * PI) * float(dur - t) / float(dur)
            if (t + off< l)
                wav3[t+off] += v
            else
                wav3 |> push(v)
        off += (44100/32)
        freq *= mul
        freq *= mul
    snd_discover = create_managed_sound(44100, wav3)

    clear(wav3)
    dur = 44100 / 8
    freq = 261.626f
    freq *= pow(mul, 14.f)
    l = 0
    off = 0;    
    for i in range(0, 6)
        l = length(wav3)
        for t in range(0,dur)
            var v = cos(float(t) / 44100.f * freq * 2.f * PI) * float(dur - t) / float(dur)
            if (t + off< l)
                wav3[t+off] += v
            else
                wav3 |> push(v)
        off += (44100/16)
        freq *= pow(mul, 9.f)
        l = length(wav3)
        for t in range(0,dur)
            var v = cos(float(t) / 44100.f * freq * 2.f * PI) * float(dur - t) / float(dur)
            if (t + off< l)
                wav3[t+off] += v
            else
                wav3 |> push(v)
        off += (44100/32)
        freq /= pow(mul, 7.f)
        
    snd_done = create_managed_sound(44100, wav3)

    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    var remaining_dt = dt
    var prev_move_dir = sokoban_next_pos - sokoban_pos
    if sokoban_next_pos != sokoban_pos
        sokoban_move_part += dt * man_vel
        if sokoban_move_part >= 1.f
            if sokoban_pushes
                var box_pos = sokoban_next_pos + (sokoban_next_pos - sokoban_pos)
                level[at(box_pos)].is_box = true;
                if (level[at(box_pos)].is_target)
                    snd_done |> play_sound(0.5)
                sokoban_pushes = false
            remaining_dt = (sokoban_move_part - 1.f) / man_vel
            sokoban_pos = sokoban_next_pos;
            sokoban_move_part = 0.f
              
    else
        sokoban_move_part = 0.f
    
    if (time_to_undo > 0.f)
        time_to_undo -= dt
    
    if get_key(VK_U)
        if time_to_undo <= 0.f
            pop_undo()
            time_to_undo = 0.05f
    elif sokoban_move_part == 0.f
        var dir = int2(0, 0)
        if get_key(VK_A) || get_key(VK_LEFT) 
            dir.x = -1
        if get_key(VK_D)|| get_key(VK_RIGHT)
            if dir.x == 0
                dir.x = 1
            else
                dir.x = 0
        if get_key(VK_W)|| get_key(VK_UP)
            dir.y = -1
        if get_key(VK_S)|| get_key(VK_DOWN)
            if dir.y == 0
                dir.y = 1
            else
                dir.y = 0
        if dir.x != 0 && dir.y != 0
            if sokoban_prev_dir.y != 0
                if level[at(int2(sokoban_pos.x + dir.x, sokoban_pos.y))].is_wall
                    dir.x = 0
                else
                    dir.y = 0
            else
                if level[at(int2(sokoban_pos.x, sokoban_pos.y + dir.y))].is_wall
                    dir.y = 0
                else
                    dir.x = 0
        var dst = sokoban_pos + dir
        if !level[at(dst)].is_wall
            if level[at(dst)].is_box
                if !level[at(dst+dir)].is_wall && !level[at(dst+dir)].is_box
                    push_undo()
                    sokoban_pushes = true;
                    level[at(dst)].is_box = false
                else
                    dir = int2(0, 0)
                    dst = sokoban_pos
            elif dst != sokoban_pos
                push_undo()
            sokoban_next_pos = dst
            sokoban_move_part = max(0.f, min(1.f, remaining_dt * man_vel))
        
        if sokoban_next_pos != sokoban_pos
            sokoban_prev_dir = dir
            if sokoban_pushes
                snd_push |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)
            else
                snd_step |> play_sound(random_float(seed)*0.1+0.5, random_float(seed)*0.5+0.5)

    for x in range(sokoban_pos.x-2,sokoban_pos.x+3)
        for y in range(sokoban_pos.y-2,sokoban_pos.y+3)
            if x >= 0 && y >= 0 && x < 48 && y < 23
                var p = at(int2(x,y))
                if (!level[p].is_visible)
                    level[p].is_visible = true
                    if (level[p].is_box)
                        snd_discover |> play_sound(0.5)

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    for x in range(0,48)
        for y in range(0,23)
            if level[at(int2(x,y))].is_visible
                if level[at(int2(x,y))].is_wall
                    draw_sokoban_wall(float(x*10), float((y+1)*12), make_color32(255, 50, 50))
                if level[at(int2(x,y))].is_box
                    if level[at(int2(x,y))].is_target
                        draw_box(float(x*10), float((y+1)*12), make_color32(255, 255, 0))
                    else
                        draw_box(float(x*10), float((y+1)*12), make_color32(50, 50, 255))
                elif level[at(int2(x,y))].is_target
                    draw_target(float(x*10), float((y+1)*12), make_color32(50, 255, 50))
    var sokoban_vis_pos = float2(sokoban_pos) + float2(sokoban_next_pos - sokoban_pos)*sokoban_move_part; 
    draw_sokoban_figure(float(int(sokoban_vis_pos.x*10.f)), float(int(sokoban_vis_pos.y*12.f)), make_color32(255,255,255))
    if sokoban_pushes
        var box_vis_pos = sokoban_vis_pos + float2(sokoban_next_pos - sokoban_pos)
        draw_box(float(int(box_vis_pos.x*10.f)), float(int(box_vis_pos.y*12.f+12.f)), make_color32(50, 50, 255))

    set_font_size(12)
    var text = "Управление: WSAD U"
    text_out(get_screen_width()/2 - int(get_text_size(text).x)/2, get_screen_height()-15, text, make_color32(255,255,255))

    return
