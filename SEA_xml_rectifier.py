import os
import re
import shutil
from typing import List, Dict, Any

# Parameters
keep_legacy_files = 1
migrate_animation = 1
underwater_model = 'false'
abovewater_model = 'true'

# Prepare log
log_file = open('xmlRectify.log', 'w')
log_count = 0

def parse_model(text_model: List[str], lod: int, mod_root: str) -> Dict[str, Any]:
    data_model = {
        'lod': lod,
        'castsShadow': "",
        'extent': "",
        'metaData': "",
        'parent': "",
        'parentLod': -1,
        'visual': "",
        'isAnimated': 0 if lod == 0 else None
    }

    ind_line = 0
    while ind_line < len(text_model):
        line = text_model[ind_line]
        if '<castsShadow>' in line:
            match = re.search(r'<castsShadow>\s*([a-zA-Z0-9_]+)\s*</castsShadow>', line)
            if match:
                data_model['castsShadow'] = match.group(1)
        elif '<parent>' in line:
            match = re.search(r'<parent>\s*([a-zA-Z0-9_/-]+)\s*</parent>', line)
            if match:
                data_model['parent'] = match.group(1)
        elif '<extent>' in line:
            match = re.search(r'<extent>\s*([a-zA-Z0-9_.]+)\s*</extent>', line)
            if match:
                data_model['extent'] = match.group(1)
        elif '<nodefullVisual>' in line:
            match = re.search(r'<nodefullVisual>\s*([a-zA-Z0-9_/-]+)\s*</nodefullVisual>', line)
            if match:
                data_model['visual'] = match.group(1)
        elif '<metaData>' in line:
            match = re.search(r'<metaData>\s*([a-zA-Z0-9_| ]+)\s*</metaData>', line)
            if match:
                data_model['metaData'] = match.group(1)
        elif '<animation>' in line and lod == 0:
            data_model['isAnimated'] = 1
        ind_line += 1

    parent_split = data_model['parent'].split('_')
    if parent_split[-1] == "lod1":
        data_model['parentLod'] = 1
    elif parent_split[-1] == "lod2":
        data_model['parentLod'] = 2
    elif parent_split[-1] == "lod3":
        data_model['parentLod'] = 3
    elif parent_split[-1] == "lod4":
        data_model['parentLod'] = 4

    if data_model['parentLod'] != -1:
        parent_split = data_model['parent'].split('/')
        data_model['parentShipID'] = parent_split[-4]
        data_model['parentFile'] = os.path.join(mod_root, *parent_split[-4:]) + '.model'

    visual_split = data_model['visual'].split('/')
    data_model['visualName'] = visual_split[-1]
    if '/lods/' in data_model['visual']:
        data_model['visualShipID'] = visual_split[-4]
        data_model['visualFile'] = os.path.join(mod_root, *visual_split[-4:]) + '.visual'
    else:
        data_model['visualShipID'] = visual_split[-3]
        data_model['visualFile'] = os.path.join(mod_root, *visual_split[-3:]) + '.visual'

    return data_model

def parse_animation(text_model: List[str]) -> (List[str], int):
    animations = []
    animation_count = 0
    for line in text_model:
        if '<animation>' in line:
            animation_count += 1
            animations.append(line.strip())
    return animations, animation_count

def parse_skeleton(text_visual: List[str]) -> List[str]:
    list_nodes = []
    is_in_node = False
    for line in text_visual:
        if not is_in_node and line.strip() == '<node>':
            is_in_node = True
        if is_in_node:
            if '<identifier>' in line:
                match = re.search(r'<identifier>\s*([a-zA-Z0-9_ ]+)\s*</identifier>', line)
                if match:
                    list_nodes.append(match.group(1))
            if line.strip() == '</node>' and (line.count('\t')==1 or line.count(' ')==4):
                is_in_node = False
                break
    return list_nodes

def parse_render_sets(text_visual: List[str]) -> List[Dict[str, Any]]:
    data_render_sets = []
    label_pattern = r'<vertices>\s*([a-zA-Z0-9_]+)\.vertices\s*</vertices>'
    ind_line = 0
    while ind_line < len(text_visual):
        line = text_visual[ind_line]
        if line.strip() == '<renderSet>':
            render_set = {
                'nodes': [],
                'tawso': "",
                'name': "",
                'materialIdentifier': "",
                'materialMfm': ""
            }
            while line.strip() != '</renderSet>':
                if '<treatAsWorldSpaceObject>' in line:
                    render_set['tawso'] = line.strip()
                elif '<node>' in line:
                    render_set['nodes'].append(line.strip())
                elif '<vertices>' in line:
                    match = re.search(label_pattern, line)
                    if match:
                        render_set['name'] = match.group(1)
                elif '<identifier>' in line:
                    render_set['materialIdentifier'] = line.strip()
                elif '<mfm>' in line:
                    render_set['materialMfm'] = line.strip()
                ind_line += 1
                line = text_visual[ind_line]
            data_render_sets.append(render_set)
        ind_line += 1
    return data_render_sets

def main():
    global log_count

    # Look for compile.info and build mod list
    list_mod = [os.path.join(root, file) for root, _, files in os.walk('.') for file in files if file == 'compile.info']

    for mod_path in list_mod:
        current_path = os.path.dirname(mod_path)
        list_model = [os.path.join(root, file) for root, _, files in os.walk(current_path) for file in files if file.endswith('.model') and not root.endswith('lods')]

        for model_path in list_model:
            folder_split = model_path.split(os.sep)
            model_type = folder_split[-2]
            ship_id = folder_split[-3]
            mod_root = os.sep.join(folder_split[:-3])
            file_model_lod0_path = os.path.dirname(model_path)
            file_model_lod0_file_name = os.path.basename(model_path)
            print(f'processing {file_model_lod0_path}/{file_model_lod0_file_name} ...')

            # Make copy of the current .model file
            if not os.path.exists(f'{file_model_lod0_path}/{file_model_lod0_file_name}bak'):
                shutil.copy(f'{file_model_lod0_path}/{file_model_lod0_file_name}', f'{file_model_lod0_path}/{file_model_lod0_file_name}bak')

            # Load data from .model and .visual files
            lod1_exist = 0
            lod2_exist = 0
            lod3_exist = 0
            lod4_exist = 0
            is_port = 0
            with open(f'{file_model_lod0_path}/{file_model_lod0_file_name}bak', 'r') as f:
                text_model_lod0 = f.readlines()
            data_model_lod0 = parse_model(text_model_lod0, 0, mod_root)
            if not os.path.exists(f'{data_model_lod0["visualFile"]}bak'):
                shutil.copy(data_model_lod0['visualFile'], f'{data_model_lod0["visualFile"]}bak')
            with open(f'{data_model_lod0["visualFile"]}bak', 'r') as f:
                text_visual_lod0 = f.readlines()
            list_nodes_lod0 = parse_skeleton(text_visual_lod0)
            render_sets_lod0 = parse_render_sets(text_visual_lod0)

            if data_model_lod0['parentLod'] == 1:
                lod1_exist = 1
                with open(data_model_lod0['parentFile'], 'r') as f:
                    text_model_lod1 = f.readlines()
                data_model_lod1 = parse_model(text_model_lod1, 1, mod_root)
                with open(data_model_lod1['visualFile'], 'r') as f:
                    text_visual_lod1 = f.readlines()
                list_nodes_lod1 = parse_skeleton(text_visual_lod1)
                render_sets_lod1 = parse_render_sets(text_visual_lod1)
                for node in list_nodes_lod1:
                    if node not in list_nodes_lod0:
                        log_file.write(f'{data_model_lod1["visualFile"]}: Skeleton node {node} not found in {data_model_lod0["visualFile"]}, please check manually.\n')
                        log_count += 1
                if data_model_lod1['parentLod'] == 2:
                    lod2_exist = 1
                    with open(data_model_lod1['parentFile'], 'r') as f:
                        text_model_lod2 = f.readlines()
                    data_model_lod2 = parse_model(text_model_lod2, 2, mod_root)
                    with open(data_model_lod2['visualFile'], 'r') as f:
                        text_visual_lod2 = f.readlines()
                    list_nodes_lod2 = parse_skeleton(text_visual_lod2)
                    render_sets_lod2 = parse_render_sets(text_visual_lod2)
                    for node in list_nodes_lod2:
                        if node not in list_nodes_lod0:
                            log_file.write(f'{data_model_lod2["visualFile"]}: Skeleton node {node} not found in {data_model_lod0["visualFile"]}, please check manually.\n')
                            log_count += 1
                    if data_model_lod2['parentLod'] == 3:
                        lod3_exist = 1
                        with open(data_model_lod2['parentFile'], 'r') as f:
                            text_model_lod3 = f.readlines()
                        data_model_lod3 = parse_model(text_model_lod3, 3, mod_root)
                        with open(data_model_lod3['visualFile'], 'r') as f:
                            text_visual_lod3 = f.readlines()
                        list_nodes_lod3 = parse_skeleton(text_visual_lod3)
                        render_sets_lod3 = parse_render_sets(text_visual_lod3)
                        for node in list_nodes_lod3:
                            if node not in list_nodes_lod0:
                                log_file.write(f'{data_model_lod3["visualFile"]}: Skeleton node {node} not found in {data_model_lod0["visualFile"]}, please check manually.\n')
                                log_count += 1
            elif data_model_lod0['parentLod'] == 4:
                lod4_exist = 1
                with open(data_model_lod0['parentFile'], 'r') as f:
                    text_model_lod4 = f.readlines()
                data_model_lod4 = parse_model(text_model_lod4, 4, mod_root)
                with open(data_model_lod4['visualFile'], 'r') as f:
                    text_visual_lod4 = f.readlines()
                list_nodes_lod4 = parse_skeleton(text_visual_lod4)
                render_sets_lod4 = parse_render_sets(text_visual_lod4)
                for node in list_nodes_lod4:
                    if node not in list_nodes_lod0:
                        log_file.write(f'{data_model_lod4["visualFile"]}: Skeleton node {node} not found in {data_model_lod0["visualFile"]}, please check manually.\n')
                        log_count += 1
            elif data_model_lod0['parentLod'] == -1:
                if model_type == 'ship' and '_ports.' in file_model_lod0_file_name.lower():
                    is_port = 1
            else:
                log_file.write(f'{file_model_lod0_path}/{file_model_lod0_file_name}: Abnormal lod hierarchy, please check manually.\n')
                log_count += 1

            # Grab animation path from ModsSDK
            if migrate_animation and data_model_lod0['isAnimated']:
                sdk_path = os.path.join('.', 'ModsSDK', data_model_lod0['visualShipID'], model_type, file_model_lod0_file_name)
                if not os.path.exists(sdk_path):
                    log_file.write(f'{file_model_lod0_path}/{file_model_lod0_file_name}: Failed to find corresponding SDK file for animation path.\n')
                    log_count += 1
                    data_model_lod0['isAnimated'] = -1
                else:
                    with open(sdk_path, 'r') as f:
                        text_model_sdk = f.readlines()
                    anim_sdk, anim_count_sdk = parse_animation(text_model_sdk)
                    if anim_count_sdk == 0:
                        log_file.write(f'{file_model_lod0_path}/{file_model_lod0_file_name}: Failed to find animation node in corresponding SDK file.\n')
                        log_count += 1
                        data_model_lod0['isAnimated'] = 0

            # Write new .model file
            with open(f'{file_model_lod0_path}/{file_model_lod0_file_name}', 'w') as f:
                f.write(f'<{file_model_lod0_file_name}>\n')
                f.write(f'\t<visual>\t{data_model_lod0["visual"]}.visual\t</visual>\n')
                if data_model_lod0['isAnimated'] == 1:
                    f.write('\t<animations>\n')
                    for anim in anim_sdk:
                        f.write(f'\t\t{anim}\n')
                    f.write('\t</animations>\n')
                else:
                    f.write('\t<animations />\n')
                f.write('\t<dyes />\n')
                f.write(f'\t<metaData>\t{data_model_lod0["metaData"]}\t</metaData>\n')
                f.write(f'</{file_model_lod0_file_name}>\n')

            # Write new .visual file
            with open(data_model_lod0['visualFile'], 'w') as f_visual_neo, open(f'{data_model_lod0["visualFile"]}bak', 'r') as f_visual_bak:
                f_visual_neo.write(f'<{data_model_lod0["visualName"]}.visual>\n')
                f_visual_neo.write('\t<skeleton>\n')
                is_in_node = False
                for line in f_visual_bak:
                    if not is_in_node and line.strip() == '<node>':
                        is_in_node = True
                    if is_in_node:
                        f_visual_neo.write(f'\t{line}')
                        if line.strip() == '</node>' and (line.count('\t')==1 or line.count(' ')==4):
                            break
                f_visual_neo.write('\t</skeleton>\n')
                f_visual_neo.write('\t<properties>\n')
                f_visual_neo.write(f'\t\t<underwaterModel>\t{underwater_model}\t</underwaterModel>\n')
                f_visual_neo.write(f'\t\t<abovewaterModel>\t{abovewater_model}\t</abovewaterModel>\n')
                f_visual_neo.write('\t</properties>\n')
                f_visual_bak.seek(0)
                is_in_bounding_box = False
                for line in f_visual_bak:
                    if not is_in_bounding_box and line.strip() == '<boundingBox>':
                        is_in_bounding_box = True
                    if is_in_bounding_box:
                        f_visual_neo.write(line)
                        if line.strip() == '</boundingBox>':
                            break
                if is_port:
                    f_visual_neo.write('\t<renderSets />\n')
                elif lod4_exist:
                    f_visual_neo.write('\t<renderSets>\n')
                    for render_set in render_sets_lod4:
                        f_visual_neo.write('\t\t<renderSet>\n')
                        f_visual_neo.write(f'\t\t\t<name>\t{render_set["name"]}\t</name>\n')
                        f_visual_neo.write(f'\t\t\t{render_set["tawso"]}\n')
                        f_visual_neo.write('\t\t\t<nodes>\n')
                        for node in render_set['nodes']:
                            f_visual_neo.write(f'\t\t\t\t{node}\n')
                        f_visual_neo.write('\t\t\t</nodes>\n')
                        f_visual_neo.write('\t\t\t<material>\n')
                        f_visual_neo.write(f'\t\t\t\t{render_set["materialIdentifier"]}\n')
                        f_visual_neo.write(f'\t\t\t\t{render_set["materialMfm"]}\n')
                        f_visual_neo.write('\t\t\t</material>\n')
                        f_visual_neo.write('\t\t</renderSet>\n')
                    f_visual_neo.write('\t</renderSets>\n')
                else:
                    if render_sets_lod0:
                        f_visual_neo.write('\t<renderSets>\n')
                        for render_set in render_sets_lod0:
                            f_visual_neo.write('\t\t<renderSet>\n')
                            f_visual_neo.write(f'\t\t\t<name>\t{render_set["name"]}\t</name>\n')
                            f_visual_neo.write(f'\t\t\t{render_set["tawso"]}\n')
                            f_visual_neo.write('\t\t\t<nodes>\n')
                            for node in render_set['nodes']:
                                f_visual_neo.write(f'\t\t\t\t{node}\n')
                            f_visual_neo.write('\t\t\t</nodes>\n')
                            f_visual_neo.write('\t\t\t<material>\n')
                            f_visual_neo.write(f'\t\t\t\t{render_set["materialIdentifier"]}\n')
                            f_visual_neo.write(f'\t\t\t\t{render_set["materialMfm"]}\n')
                            f_visual_neo.write('\t\t\t</material>\n')
                            f_visual_neo.write('\t\t</renderSet>\n')
                        if lod1_exist:
                            for render_set in render_sets_lod1:
                                f_visual_neo.write('\t\t<renderSet>\n')
                                f_visual_neo.write(f'\t\t\t<name>\t{render_set["name"]}\t</name>\n')
                                f_visual_neo.write(f'\t\t\t{render_set["tawso"]}\n')
                                f_visual_neo.write('\t\t\t<nodes>\n')
                                for node in render_set['nodes']:
                                    f_visual_neo.write(f'\t\t\t\t{node}\n')
                                f_visual_neo.write('\t\t\t</nodes>\n')
                                f_visual_neo.write('\t\t\t<material>\n')
                                f_visual_neo.write(f'\t\t\t\t{render_set["materialIdentifier"]}\n')
                                f_visual_neo.write(f'\t\t\t\t{render_set["materialMfm"]}\n')
                                f_visual_neo.write('\t\t\t</material>\n')
                                f_visual_neo.write('\t\t</renderSet>\n')
                            if lod2_exist:
                                for render_set in render_sets_lod2:
                                    f_visual_neo.write('\t\t<renderSet>\n')
                                    f_visual_neo.write(f'\t\t\t<name>\t{render_set["name"]}\t</name>\n')
                                    f_visual_neo.write(f'\t\t\t{render_set["tawso"]}\n')
                                    f_visual_neo.write('\t\t\t<nodes>\n')
                                    for node in render_set['nodes']:
                                        f_visual_neo.write(f'\t\t\t\t{node}\n')
                                    f_visual_neo.write('\t\t\t</nodes>\n')
                                    f_visual_neo.write('\t\t\t<material>\n')
                                    f_visual_neo.write(f'\t\t\t\t{render_set["materialIdentifier"]}\n')
                                    f_visual_neo.write(f'\t\t\t\t{render_set["materialMfm"]}\n')
                                    f_visual_neo.write('\t\t\t</material>\n')
                                    f_visual_neo.write('\t\t</renderSet>\n')
                                if lod3_exist:
                                    for render_set in render_sets_lod3:
                                        f_visual_neo.write('\t\t<renderSet>\n')
                                        f_visual_neo.write(f'\t\t\t<name>\t{render_set["name"]}\t</name>\n')
                                        f_visual_neo.write(f'\t\t\t{render_set["tawso"]}\n')
                                        f_visual_neo.write('\t\t\t<nodes>\n')
                                        for node in render_set['nodes']:
                                            f_visual_neo.write(f'\t\t\t\t{node}\n')
                                        f_visual_neo.write('\t\t\t</nodes>\n')
                                        f_visual_neo.write('\t\t\t<material>\n')
                                        f_visual_neo.write(f'\t\t\t\t{render_set["materialIdentifier"]}\n')
                                        f_visual_neo.write(f'\t\t\t\t{render_set["materialMfm"]}\n')
                                        f_visual_neo.write('\t\t\t</material>\n')
                                        f_visual_neo.write('\t\t</renderSet>\n')
                        f_visual_neo.write('\t</renderSets>\n')
                    else:
                        log_file.write(f'{data_model_lod0["visualFile"]}: No renderSet found in lod0 visual.\n')
                        log_count += 1
                        f_visual_neo.write('\t<renderSets />\n')
                f_visual_neo.write('\t<lods>\n')
                f_visual_neo.write('\t\t<lod>\n')
                f_visual_neo.write(f'\t\t\t<extent>\t{data_model_lod0["extent"]}\t</extent>\n')
                f_visual_neo.write(f'\t\t\t<castsShadow>\t{data_model_lod0["castsShadow"]}\t</castsShadow>\n')
                if render_sets_lod0:
                    f_visual_neo.write('\t\t\t<renderSets>\n')
                    for render_set in render_sets_lod0:
                        f_visual_neo.write(f'\t\t\t\t<renderSet>\t{render_set["name"]}\t</renderSet>\n')
                    f_visual_neo.write('\t\t\t</renderSets>\n')
                else:
                    f_visual_neo.write('\t\t\t<renderSets />\n')
                f_visual_neo.write('\t\t</lod>\n')
                if lod1_exist:
                    f_visual_neo.write('\t\t<lod>\n')
                    f_visual_neo.write(f'\t\t\t<extent>\t{data_model_lod1["extent"]}\t</extent>\n')
                    f_visual_neo.write(f'\t\t\t<castsShadow>\t{data_model_lod1["castsShadow"]}\t</castsShadow>\n')
                    f_visual_neo.write('\t\t\t<renderSets>\n')
                    for render_set in render_sets_lod1:
                        f_visual_neo.write(f'\t\t\t\t<renderSet>\t{render_set["name"]}\t</renderSet>\n')
                    f_visual_neo.write('\t\t\t</renderSets>\n')
                    f_visual_neo.write('\t\t</lod>\n')
                    if lod2_exist:
                        f_visual_neo.write('\t\t<lod>\n')
                        f_visual_neo.write(f'\t\t\t<extent>\t{data_model_lod2["extent"]}\t</extent>\n')
                        f_visual_neo.write(f'\t\t\t<castsShadow>\t{data_model_lod2["castsShadow"]}\t</castsShadow>\n')
                        f_visual_neo.write('\t\t\t<renderSets>\n')
                        for render_set in render_sets_lod2:
                            f_visual_neo.write(f'\t\t\t\t<renderSet>\t{render_set["name"]}\t</renderSet>\n')
                        f_visual_neo.write('\t\t\t</renderSets>\n')
                        f_visual_neo.write('\t\t</lod>\n')
                        if lod3_exist:
                            f_visual_neo.write('\t\t<lod>\n')
                            f_visual_neo.write(f'\t\t\t<extent>\t{data_model_lod3["extent"]}\t</extent>\n')
                            f_visual_neo.write(f'\t\t\t<castsShadow>\t{data_model_lod3["castsShadow"]}\t</castsShadow>\n')
                            f_visual_neo.write('\t\t\t<renderSets>\n')
                            for render_set in render_sets_lod3:
                                f_visual_neo.write(f'\t\t\t\t<renderSet>\t{render_set["name"]}\t</renderSet>\n')
                            f_visual_neo.write('\t\t\t</renderSets>\n')
                            f_visual_neo.write('\t\t</lod>\n')
                elif lod4_exist:
                    f_visual_neo.write('\t\t<lod>\n')
                    f_visual_neo.write(f'\t\t\t<extent>\t{data_model_lod4["extent"]}\t</extent>\n')
                    f_visual_neo.write(f'\t\t\t<castsShadow>\t{data_model_lod4["castsShadow"]}\t</castsShadow>\n')
                    f_visual_neo.write('\t\t\t<renderSets>\n')
                    for render_set in render_sets_lod4:
                        f_visual_neo.write(f'\t\t\t\t<renderSet>\t{render_set["name"]}\t</renderSet>\n')
                    f_visual_neo.write('\t\t\t</renderSets>\n')
                    f_visual_neo.write('\t\t</lod>\n')
                f_visual_neo.write('\t</lods>\n')
                f_visual_neo.write(f'</{data_model_lod0["visualName"]}.visual>\n')

    log_file.close()
    print('Routine finished.')
    if log_count > 0:
        print('Issue(s) occurred, please check log file.')

if __name__ == '__main__':
    main()