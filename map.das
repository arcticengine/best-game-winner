require fio
require json

struct Map
    he: int

var map: Map

[export]
def test_map()
    var passed = true
    // here will be tests for map load and creation
    passed = load_map()
    if passed
        print("test_map passed\n")
    else
        print("test_map failed")
    return passed

[export]
def load_map(): bool
    if is_file_exists("map.json")
        print("map file found\n")
    else
        print("Error: no map file\n")
        return false
    var file_text: string
    fopen("map.json", "rb") <| $(f)
        file_text = fread(f)
        print("json content: {file_text}\n")
    var error: string
    var content = read_json(file_text, error)
    print("parsed content: {content}\n")
    return true

