require fio
// require json
require strings
require rtti
require daslib/media
require json_boost

let fname = "map.json"

def GetJson (fileName:string): JsonValue?
    var json: JsonValue?
    var root:string = get_das_root()
    fopen(fileName, "rb") <| $ ( f )
        fread(f) <| $ ( data )
            var file_length = length(data)
            if file_length == 0
                panic("Error: either no {fileName} file or the file is empty\n")
            //print ( "\n{fileName}\n" )
            //print("before read {int(heap_bytes_allocated())} {int(string_heap_bytes_allocated())}\n")
            var error = ""
            json = read_json(data, error)
            if json == null
                panic("failed to parse, {error}\n")
    return json

def get_jsonval_variant(v: JsonValue?)
    if v is _object
        return "table<string; JsonValue?>"
    elif v is _array
        return "array<JsonValue?>"
    elif v is _string
        return "string"
    elif v is _number
        return "double"
    elif v is _bool
        return "bool"
    elif v is _null
        return "null"
    else
        return "unknown"
    

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

variant PropertyVariant
    _string : string
    _number : double
    _bool   : bool
    _null   : void?


// struct Property
//     name: string
//     // type_: type // how to create type var?
//     // propertytype: string
//     // value: type_
//     value: PropertyVariant

struct Layer
    chunks: array<Chunk>
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
    properties: table<string; PropertyVariant>
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
    properties:  table<string; PropertyVariant>
    tile: int

struct Frame
    duration: int
    tileid: int

struct Tile
    animation: array<Frame>
    id: int
    image: Image
    imageheight: int
    imagewidth: int
    objectgroup: Layer
    probability: double
    properties: table<string; PropertyVariant>
    terrain: Terrain[4]
    type_: string

// struct Transformations
//     hflip: bool
//     vflip: bool
//     rotate: bool
//     preferuntransformed: bool

enum Objectalignment
    unspecified
    topleft
    top
    topright
    left
    center
    right
    bottomleft
    bottom
    bottomright

struct WangTile
    tileid: int
    wangid: array<uint>

struct WangColor
    color: uint
    name: string
    probability: double
    properties:  table<string; PropertyVariant>
    tile: int

struct WangSet
    colors: array<WangColor>
    name: string
    properties: table<string; PropertyVariant>
    tile: int
    type_: string
    wangtiles: array<WangTile>

struct Tileset
    backgroundcolor: uint
    columns: int
    firstgid: int
    grid: Grid
    // image: string
    image: Image
    imageheight: int
    imagewidth: int
    margin: int
    name: string
    objectalignment: Objectalignment
    properties: table<string; PropertyVariant>
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
    width: int
    hexsidelength: int
    infinite: bool
    layers: array<Layer>
    nextlayerid: int
    nextobjectid: int
    orientation: Orientation
    parallaxoriginx: double
    parallaxoriginy: double
    properties: table<string; PropertyVariant>
    renderorder: Renderorder
    staggeraxis: Staggeraxis
    staggerindex: Staggerindex
    tiledversion: string
    tileheight: int
    tilewidth: int
    tilesets: array<Tileset>
    type_: string
    version: string

var map: Map

[export]
def load_map(): bool    
    // var file_text: string
    // fopen(fname, "rb") <| $(f)
    //     file_text = fread(f)
    //     print("json content: {file_text}\n")
    // var file_length = length(file_text)
    // if file_length == 0
    //     print("Error: either no {fname} file or the file is empty\n")
    //     return false
    // print("map file size: {file_length}\n")
      
    // var error: string
    // var content = read_json(file_text, error)
    // print("parsed content: {content}\n")
    // unsafe
        // print("parsed content: {find(content.value._object,"height")}\n")

    
    var json: JsonValue? = GetJson (fname)
    //print("We got json:\n" + write_json(json))

    var jsonTable: table<string; JsonValue?>

    print("\nDig in json:\n")
    if json is _object
        jsonTable := json as _object
        var i = 0
        for k,v in keys(jsonTable), values(jsonTable)
            print("Pair" + string(i) + ": " + "{k}:{v}\n")
            i++
            if k == "backgroundcolor"
                map.backgroundcolor = string_to_uint(v as _string) + 0xff000000
            elif k == "compressionlevel"
                map.compressionlevel = int(v as _number)
            elif k == "height"
                map.height = int(v as _number)
            elif k == "width"
                map.width = int(v as _number)
            elif k == "hexsidelength"
                map.hexsidelength = int(v as _number)
            elif k == "infinite"
                map.infinite = v as _bool
            elif k == "layers"
                var layer_jsonTable: table<string; JsonValue?>
                if v is _array
                    for layerv in v as _array
                        var _layer <- [[Layer]]
                        layer_jsonTable := layerv as _object
                        print("\n{get_jsonval_variant(layer_jsonTable["chunks"])}\n")
                        var chunk_jsonTable: table<string; JsonValue?>
                        for chunkv in layer_jsonTable["chunks"] as _array
                            chunk_jsonTable := chunkv as _object
                            print("\n{get_jsonval_variant(chunk_jsonTable["data"])}\n")
                            var _chunk = [[Chunk]]
                            // for datav in (chunk_jsonTable["data"] as _string)
                                // print("\n{get_jsonval_variant(datav)}\n")
                            _chunk.data = chunk_jsonTable["data"] as _string
                            // what to do with that data?
                            // it can be processed after reading all json
                            _layer.chunks |> push(_chunk)
                        // let _draworder = layer_jsonTable["draworder"] as _string
                        // if layer_jsonTable["draworder"] as _string == "topdown"
                        //     _layer.draworder = Draworder topdown // for objects
                        _layer.height = int(layer_jsonTable["height"] as _number)
                        _layer.width = int(layer_jsonTable["width"] as _number)
                        _layer.id = int(layer_jsonTable["height"] as _number)
                        // _layer.image = layer_jsonTable["image"] as _string
                        // _layer.layer?
                        // _layer.locked = layer_jsonTable["locked"] as _bool
                        _layer.name = layer_jsonTable["name"] as _string
                        // _layer.objects?
                        // _layer.offsetx = layer_jsonTable["offsetx"] as _number
                        // _layer.offsety = layer_jsonTable["offsety"] as _number
                        _layer.opacity = layer_jsonTable["opacity"] as _number
                        // _layer.parallaxx = layer_jsonTable["parallaxx"] as _number
                        // _layer.parallaxy = layer_jsonTable["parallaxy"] as _number
                        // for vv in layer_jsonTable["properties"] as _array
                        //     add_property(_layer.properties, vv)
                        // _layer.repeatx = layer_jsonTable["repeatx"] as _bool
                        // _layer.repeaty = layer_jsonTable["repeaty"] as _bool
                        _layer.startx = int(layer_jsonTable["startx"] as _number)
                        _layer.starty = int(layer_jsonTable["starty"] as _number)
                        // _layer.tintcolor = string_to_uint(layer_jsonTable["tintcolor"] as _string) + 0xff000000
                        // _layer.transparentcolor = string_to_uint(layer_jsonTable["transparentcolor"] as _string) + 0xff000000
                        _layer.type_ = layer_jsonTable["type"] as _string
                        _layer.visible = layer_jsonTable["visible"] as _bool
                        _layer.x = int(layer_jsonTable["x"] as _number)
                        _layer.y = int(layer_jsonTable["y"] as _number)
                        push_clone(map.layers, _layer)
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
                if v is _array
                    for vv in v as _array
                        add_property(map.properties, vv)
            elif k == "renderorder"
                if v as _number == double(0)
                    map.renderorder = Renderorder right_down
                elif v as _number == double(1)
                    map.renderorder = Renderorder right_up
                elif v as _number == double(2)
                    map.renderorder = Renderorder left_down
                elif v as _number == double(3)
                    map.renderorder = Renderorder left_up
                else
                    print("\nerror: wrong renderorder number in {fname}\n")
            elif k == "staggeraxis"
                if v as _string == "x"
                    map.staggeraxis = Staggeraxis x
                elif v as _string == "y"
                    map.staggeraxis = Staggeraxis y
                else
                    print("\nerror: wrong staggeraxis in {fname}\n")
            elif k == "staggerindex"
                if v as _string == "odd"
                    map.staggerindex = Staggerindex odd
                elif v as _string == "even"
                    map.staggerindex = Staggerindex even
                else
                    print("\nerror: incorrect staggerindex in {fname}\n")
            elif k == "tiledversion"
                map.tiledversion = v as _string
            elif k == "tileheight"
                map.tileheight = int(v as _number)
            elif k == "tilewidth"
                map.tilewidth = int(v as _number)
            elif k == "tilesets"
                if v is _array
                    for vv in v as _array
                        var TjsonTable: table<string; JsonValue?>
                        TjsonTable := vv as _object
                        var _tileset <- [[Tileset]]
                        for kkk,vvv in keys(TjsonTable), values(TjsonTable)
                            if kkk == "backgroundcolor"
                                _tileset.backgroundcolor = string_to_uint(vvv as _string) + 0xff000000
                            elif kkk == "columns"
                                _tileset.columns = int(vvv as _number)
                            elif kkk == "firstgid"
                                _tileset.firstgid = int(vvv as _number)
                            elif kkk == "grid"
                                var GjsonTable: table<string; JsonValue?> := vvv as _object
                                _tileset.grid.height = int(GjsonTable["height"] as _number)
                                _tileset.grid.width = int(GjsonTable["width"] as _number)
                                if GjsonTable["orientation"] as _string == "orthogonal"
                                    _tileset.grid.orientation = Orientation orthogonal
                                else
                                    _tileset.grid.orientation = Orientation isometric
                            elif kkk == "image"
                                _tileset.image <- create_image(vvv as _string)
                            elif kkk == "imageheight"
                                _tileset.imageheight = int(vvv as _number)
                            elif kkk == "imagewidth"
                                _tileset.imagewidth = int(vvv as _number)
                            elif kkk == "margin"
                                _tileset.margin = int(vvv as _number)
                            elif kkk == "name"
                                _tileset.name = vvv as _string
                            elif kkk == "objectalignment"
                                if vvv as _string == "unspecified"
                                    _tileset.objectalignment = Objectalignment unspecified
                                if vvv as _string == "topleft"
                                    _tileset.objectalignment = Objectalignment topleft
                                if vvv as _string == "top"
                                    _tileset.objectalignment = Objectalignment top
                                if vvv as _string == "topright"
                                    _tileset.objectalignment = Objectalignment topright
                                if vvv as _string == "left"
                                    _tileset.objectalignment = Objectalignment left
                                if vvv as _string == "center"
                                    _tileset.objectalignment = Objectalignment center
                                if vvv as _string == "right"
                                    _tileset.objectalignment = Objectalignment right
                                if vvv as _string == "bottomleft"
                                    _tileset.objectalignment = Objectalignment bottomleft
                                if vvv as _string == "bottom"
                                    _tileset.objectalignment = Objectalignment bottom
                                if vvv as _string == "bottomright"
                                    _tileset.objectalignment = Objectalignment bottomright
                            elif kkk == "properties"
                                for vvvv in vvv as _array
                                    add_property(_tileset.properties, vvvv)
                            elif kkk == "source"
                                _tileset.source = vvv as _string
                            elif kkk == "spacing"
                                _tileset.spacing = int(vvv as _number)
                            elif kkk == "terrains"
                                var TerrjsonTable: table<string; JsonValue?> := vvv as _object
                                var _terr: Terrain
                                _terr.name = TerrjsonTable["name"] as _string
                                for vvvv in TerrjsonTable["properties"] as _array
                                    add_property(_terr.properties, vvvv)
                                _terr.tile = int(TerrjsonTable["tile"] as _number)
                                emplace(_tileset.terrains, _terr)
                            elif kkk == "tilecount"
                                _tileset.tilecount = int(vvv as _number)
                            elif kkk == "tiledversion"
                                _tileset.tiledversion = vvv as _string
                            elif kkk == "tileheight"
                                _tileset.tileheight = int(vvv as _number)
                            elif kkk == "tileoffset"
                                _tileset.tileoffset[0] = int((vvv as _array)[0] as _number)
                                _tileset.tileoffset[1] = int((vvv as _array)[1] as _number)
                            elif kkk == "tiles"
                                for vvvv in vvv as _array
                                    var TijsonTable: table<string; JsonValue?>
                                    TijsonTable := vvvv as _object
                                    var _tile: Tile
                                    for kkkkk, vvvvv in keys(TijsonTable), values(TijsonTable)
                                        if kkkkk == "animation"
                                            for vvvvvv in vvvvv as _array
                                                var _frame: Frame
                                                _frame.duration = int((vvvvvv as _object)["duration"] as _number)
                                                _frame.tileid = int((vvvvvv as _object)["tileid"] as _number)
                                                push(_tile.animation, _frame)
                                        elif kkkkk == "id"
                                            _tile.id = int(vvvvv as _number)
                                        elif kkkkk == "image"
                                            _tile.image <- create_image(vvvvv as _string)
                                        elif kkkkk == "imageheight"
                                            _tile.imageheight = int(vvvvv as _number)
                                        elif kkkkk == "imagewidth"
                                            _tile.imagewidth = int(vvvvv as _number)
                                        // elif kkkkk == "objectgroup"
                                        elif kkkkk == "probability"
                                            _tile.probability = vvvvv as _number
                                        elif kkkkk == "properties"
                                            for vvvvvv in vvvvv as _array
                                                add_property(_tile.properties, vvvvvv)
                                        // elif kkkkk == "terrain"
                                        elif kkkkk == "type"
                                            _tile.type_ = vvvvv as _string
                                    push_clone(_tileset.tiles, _tile)
                            elif kkk == "tilewidth"
                                _tileset.tilewidth = int(vvv as _number)
                            // elif kkk == "transformations"
                            //     if vvv == "hflip"
                            //         _tileset.transformations.hflip = true // wrong, vvv is _object
                            //     elif vvv == "vflip"
                            //         _tileset.transformations.vflip = true
                            //     elif vvv == "rotate"
                            //         _tileset.transformations.rotate = true
                            //     elif vvv == "preferuntransformed"
                            //         _tileset.transformations.preferuntransformed = true
                            elif kkk == "transparentcolor"
                                _tileset.transparentcolor = string_to_uint(vvv as _string) + 0xff000000
                            elif kkk == "type"
                                _tileset.type_ = vvv as _string
                            elif kkk == "version"
                                _tileset.version = vvv as _string
                            // elif kkk == "wangsets"
                            
                        push_clone(map.tilesets, _tileset)
            elif k == "type"
                if v as _string != "map"
                    print("\nerror: {fname} type is not map\n")
                else
                    map.type_ = "map"
            elif k == "version"
                map.version = v as _string

            
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

def add_property(var tbl: table<string; PropertyVariant>&; v: JsonValue?)
    var jsonTable: table<string; JsonValue?>
    jsonTable := v as _object
    let type_ = jsonTable["type"] as _string
    let name_ = jsonTable["name"] as _string
    if type_ == "string"
        tbl[name_] = [[PropertyVariant _string = jsonTable["value"] as _string]]
    elif type_ == "number"
        tbl[name_] = [[PropertyVariant _number = jsonTable["value"] as _number]]
    elif type_ == "bool"
        tbl[name_] = [[PropertyVariant _bool = jsonTable["value"] as _bool]]
    else
        print("\nerror: unknown property type {type_} in {fname}\n")