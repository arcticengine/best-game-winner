require fio
// require json
require strings

require json_boost

def GetJson (fileName:string): JsonValue?
    var json: JsonValue?
    var root:string = get_das_root()
    // let fname = "map.json"
    fopen(fileName, "rb") <| $ ( f )
        fread(f) <| $ ( data )
            //print ( "\n{fileName}\n" )
            //print("before read {int(heap_bytes_allocated())} {int(string_heap_bytes_allocated())}\n")
            var error = ""
            json = read_json(data, error)
            if json == null
                panic("failed to parse, {error}\n")
    return json

enum Renderorder
    right_down
    right_up
    left_down
    left_up

struct Chunk
    data: string
    height: int
    width: int
    x: int
    y: int

enum Compression
    empty
    zlib
    gzip
    zstd

enum Draworder
    topdown
    index

enum Encoding
    csv
    base64

// struct Object
//     ellipse bool
//     gid int
//     height double
//     id int
//     name string
//     point bool
//     polygon array
//     polyline array
//     properties array
//     rotation double
//     template string
//     text Text
//     type string
//     visible bool
//     width double
//     x double
//     y double

struct Properties
    name: string
    // type_: type // how to create type var?
    propertytype: string
    // value: type_
    value: string

struct Layer
    chunks: Chunk
    compression: Compression
    data: string
    draworder: Draworder
    encoding: Encoding
    height: int
    id: int
    image: string
    // layers: array<Layer>
    locked: bool
    name: string
    // objects: array<Object>
    offsetx: double
    offsety: double
    opacity: double
    parallaxx: double
    parallaxy: double
    properties: array<Properties>
    repeatx: bool
    repeaty: bool
    startx: int
    starty: int
    tintcolor: uint
    transparentcolor: uint
    type_: string
    visible: bool
    width: int
    x: int
    y: int

enum Staggeraxis
    x
    y

enum Staggerindex
    odd
    even

enum Orientation
    orthogonal
    isometric
    staggered
    hexagonal

struct Grid
    height: int
    width: int
    orientation: Orientation

struct Terrain
    name: string
    properties: array<Properties>
    tile: int

struct Frame
    duration: int
    tileid: int

struct Tile
    animation: array<Frame>
    id: int
    image: string
    imageheight: int
    imagewidth: int
    objectgroup: Layer
    probability: double
    properties: array<Properties>
    terrain: Terrain[4]
    type_: string

struct Transformations
    hflip: bool
    vflip: bool
    rotate: bool
    preferuntransformed: bool

struct WangTile
    tileid: int
    wangid: array<uint>

struct WangColor
    color: uint
    name: string
    probability: double
    properties: array<Properties>
    tile: int

struct WangSet
    colors: array<WangColor>
    name: string
    properties: array<Properties>
    tile: int
    type_: string
    wangtiles: array<WangTile>

struct Tileset
    backgroundcolor: uint
    columns: int
    firstgid: int
    grid: Grid
    image: string
    imageheight: int
    imagewidth: int
    margin: int
    name: string
    objectalignment: string
    properties: array<Properties>
    source: string
    spacing: int
    terrains: array<Terrain>
    tilecount: int
    tiledversion: string
    tileheight: int
    tileoffset: int[2]
    tiles: array<Tile>
    tilewidth: int
    // transformations: Transformations
    transparentcolor: uint
    type_: string
    version: string
    wangsets: array<WangSet>

struct Map
    backgroundcolor: uint
    compressionlevel: int
    height: int
    hexsidelength: int
    infinite: bool
    layers: array<Layer>
    nextlayerid: int
    nextobjectid: int
    orientation: Orientation
    parallaxoriginx: double
    parallaxoriginy: double
    properties: array<Properties>
    renderorder: Renderorder
    staggeraxis: Staggeraxis
    staggerindex: Staggerindex
    tiledversion: string
    tileheight: int
    tilesets: array<Tileset>
    tilewidth: int
    type_: string
    version: string
    width: int

var map: Map

[export]
def load_map(): bool    
    // var file_text: string
    // fopen("map.json", "rb") <| $(f)
    //     file_text = fread(f)
    //     print("json content: {file_text}\n")
    // var file_length = length(file_text)
    // if file_length == 0
    //     print("Error: either no map.json file or the file is empty\n")
    //     return false
    // print("map file size: {file_length}\n")
      
    // var error: string
    // var content = read_json(file_text, error)
    // print("parsed content: {content}\n")
    // unsafe
        // print("parsed content: {find(content.value._object,"height")}\n")

    
    var json: JsonValue? = GetJson ("map.json")
    //print("We got json:\n" + write_json(json))

    var jsonTable: table<string; JsonValue?>

    print("\nDig in json:")
    if json is _object
        jsonTable := json as _object
        var i = 0
        for k,v in keys(jsonTable), values(jsonTable)
            print("\nPair" + string(i) + ": " + "{k}:{v}")
            i++
            if k == "backgroundcolor"
                map.backgroundcolor = string_to_uint(v as _string)
            elif k == "compressionlevel"
                map.compressionlevel = int(v as _number)
            elif k == "height"
                map.height = int(v as _number)
            elif k == "hexsidelength"
                map.hexsidelength = int(v as _number)
            elif k == "infinite"
                map.infinite = v as _bool
            elif k == "layers"
                var jsonTable2: table<string; JsonValue?>
                if v is _object
                    jsonTable2 := v as _object
                    var ii = 0
                    for k2,v2 in keys(jsonTable2), values(jsonTable2)
                        print("\nPair in layers" + string(ii) + ": " + "{k}:{v}")
                        ii++
                        // if k2 == ""
                        //TODO: adding layers
            elif k == "nextlayerid"
                map.nextlayerid = int(v as _number)
            elif k == "nextobjectid"
                map.nextobjectid = int(v as _number)
            elif k == "orientation"
                var orient_string = v as _string
                if orient_string == "orthogonal"
                    map.orientation = Orientation orthogonal
                if orient_string == "isometric"
                    map.orientation = Orientation isometric
                if orient_string == "staggered"
                    map.orientation = Orientation staggered
                if orient_string == "hexagonal"
                    map.orientation = Orientation hexagonal
            elif k == "parallaxoriginx"
                map.parallaxoriginx = double(v as _number)
            elif k == "parallaxoriginy"
                map.parallaxoriginy = double(v as _number)
            elif k == "properties"
                var jsonTable2: table<string; JsonValue?>
                // if v is _object
                jsonTable2 := v as _object
                var ii = 0
                for k2,v2 in keys(jsonTable2), values(jsonTable2)
                    print("\nPair in properties" + string(ii) + ": " + "{k}:{v}")
                    ii++
            // elif k == "renderorder"
            //     map.
            // elif k == "staggeraxis"
            //     map.
            // elif k == "staggerindex"
            //     map.
            // elif k == "tiledversion"
            //     map.
            // elif k == "tileheight"
            //     map.
            // elif k == "tilesets"
            //     map.
            // elif k == "tilewidth"
            //     map.
            // elif k == "type"
            //     map.
            // elif k == "version"
            //     map.
            // elif k == "width"
                    // map.
            
    print("\nmap: {map}\n")
    return true

def string_to_uint(s: string): uint
    var n: int = 0
        //parsing numbers from text
    var r = 10
    for c in s
        // no switch case in daScript lol
        // here we can also use n=c-48+n*r
        if c == '0'
            n = 0 + n * r
        elif c == '1'
            n = 1 + n * r
        elif c == '2'
            n = 2 + n * r
        elif c == '3'
            n = 3 + n * r
        elif c == '4'
            n = 4 + n * r
        elif c == '5'
            n = 5 + n * r
        elif c == '6'
            n = 6 + n * r
        elif c == '7'
            n = 7 + n * r
        elif c == '8'
            n = 8 + n * r
        elif c == '9'
            n = 9 + n * r
        elif c == ' ' || c == '\n'
            return uint(n)
            // r = 1
            // n = 0
            // continue
        else
            continue
        if n*100 < 0 || n > 214748364
            return uint(n)
            // n = 0
            // continue
        if n < 0
            print("\n uint from string parsing error: number is less than 0\n")
            return 0x0
    return uint(n)