import json

file = open('import.json', 'r')
converter = json.loads(file.read())
thing = list(converter.keys())

markdownMake = "All of the LUA APIs in this page!\n\nIncludes all VARIABLES, FUNCTIONS and EVENTS on all and what they do!\n\nIf there's something below, but don't know what they do? You can use CTRL+F and find which function or variable and then see what it does for the function, event or variable!\n\n<small>This was generated, click [here](https://github.com/NAEL2XD/LuApps/blob/main/extras/main.py) for the code.</small>\n\nThere are a total of:\n"

for i in range(3):
    markdownMake += f'* {len(list(converter[thing[i]].keys()))} {thing[i]}.\n'

for i in range(3):
    markdownMake += f"\n# {thing[i].capitalize()}\n"
    for j in range(len(converter[thing[i]])):
        bruh = list(converter[thing[i]].keys())
        inside = converter[thing[i]][bruh[j]]

        def shit(piss, inside):
            if piss == 'variables':
                return f'` -> `{inside["returns"]}'
            else:
                if piss == 'events' or inside["returns"] == 'void':
                    return f'({inside["args"]})'
                else:
                    return f'({inside["args"]})` -> `{inside["returns"]}'

        markdownMake += f'### `{bruh[j] + shit(thing[i], inside)}`\n{inside["documentation"]}\n\n'

save = open('export.md', 'w')
save.write(markdownMake)
save.close()