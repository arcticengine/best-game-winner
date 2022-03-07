require fio
require json
require strings

struct Map
    he: int

var map: Map

[export]
def load_map(): bool    
    var file_text: string
    fopen("map.json", "rb") <| $(f)
        file_text = fread(f)
        print("json content: {file_text}\n")
    var file_length = length(file_text)
    if file_length == 0
        print("Error: either no map.json file or the file is empty\n")
        return false
    print("map file size: {file_length}\n")
      
    var error: string
    var content = read_json(file_text, error)
    print("parsed content: {content}\n")
    return true

