import os

directory = '/Users/hi/Projects/entermedia/eme_world/test'

for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            if 'package:eme_world/' in content:
                content = content.replace('package:eme_world/', 'package:flutter_eme_base/')
                with open(filepath, 'w') as f:
                    f.write(content)
                print(f'Updated {filepath}')
