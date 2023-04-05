#!/usr/bin/env python3
import sys
import os
import glob

try:
    import fontforge
except :
    sys.stderr.write("fontforge package not found in the python path\n")
    sys.exit(1)
    
FIRST_FONT_CHARACTER_INDEX = 0x100

class NoSourceSvgDirectoriesException(Exception):
    pass

class FontforgeFont():
    
    def __init__(self, kerning=15):
        #initialize the font
        self.font = fontforge.font()
        # starts  in the character code for !
        self.font_character_index = FIRST_FONT_CHARACTER_INDEX
        
        #other fontforge options:
        self.kerning = kerning
        
    def add_character(self, svg_file):
        c = self.font.createChar(self.font_character_index)
        #import the svg file
        c.importOutlines(svg_file.path)
        #set the margins to the vectorial image
        c.left_side_bearing = self.kerning
        c.right_side_bearing = self.kerning
        
        #update the SvgFile instance with the character index assigned for it
        svg_file.set_character_index(self.font_character_index)
        
        self.font_character_index += 1
        
        
    def save_to_file(self, path):
        self.font.generate(path)
    
class SvgFile():
    def __init__(self, path, use_dirname_as_prefix=False):
        self.path = path
        
        #initalize the name
        self.name = os.path.basename(path).split('.')[0]
        if (use_dirname_as_prefix):
            prefix = os.path.basename(os.path.dirname(path))
            self.name = "%s-%s" % (prefix, self.name)  
        
        self.character_index = None
        self.character = None
    
    def set_character_index(self, character_index):
        self.character_index = character_index
        self.character = chr(character_index)
    
class SvgToFontGenerator():
    
    def __init__(self, source_directories, target_ttf_file):
        self.use_svg_dirname_as_prefix = (len(source_directories) > 1)
        self.source_directories = self.validate_source_directories(
                                                            source_directories)
        self.target_ttf_file = target_ttf_file
        
        self.source_svg_files = self.collect_svg_files()
        
    def validate_source_directories(self, source_directories):
        ret_directories = list()
        for directory in source_directories:
            directory = os.path.realpath(directory)
            if os.path.exists(directory):
                ret_directories.append(directory)
            else:
                sys.stderr("path \"%s\" for source svg files does not exist." % \
                            directory)
        if len(ret_directories) == 0:
            raise NoSourceSvgDirectoriesException("No valid paths for source \
                                                  svg files provided")
        return ret_directories
    
    
    def collect_svg_files(self):
        file_paths = list()
        for directory in self.source_directories:
            file_paths += [os.path.join(directory, filename) 
                           for filename in list(glob.glob1(directory, "*.svg"))]
        
        svg_files = [SvgFile(file_path, self.use_svg_dirname_as_prefix) 
                     for file_path in file_paths]
        
        svg_files.sort(key=lambda a: a.name.lower())
        return svg_files
         
    def generate(self):
        
        #start by processing the file
        font = FontforgeFont()
        for svg_file in self.source_svg_files:
            font.add_character(svg_file);
        font.save_to_file(self.target_ttf_file)

if __name__ == "__main__":
    fontGenerator = SvgToFontGenerator(['./icons/icons8', './icons'], './fonts/Items.ttf')
    fontGenerator.generate()
    names = [svg.name.lower().replace("-", "_").replace("icons8_","") for svg in fontGenerator.source_svg_files]
    with open('./lib/item_icons.dart', 'w') as f:
        f.write("""
/* generated code, do not edit */
// ignore_for_file: constant_identifier_names
import 'package:flutter/widgets.dart';
import 'package:kitchenowl/models/item.dart';

class ItemIcons {
  ItemIcons._();

  static const _kFontFam = 'Items';
  static const String? _kFontPkg = null;

  static IconData? get(Item item) {
    return map[item.icon];
  }

  static const Map<String, IconData> map = {\n""")

        for name in names:
            f.write(f"""    "{name}": {name},\n""")

        f.write("""  };\n\n""")

        for i, name in enumerate(names):
            f.write(f"""  static const IconData {name} = IconData({i+FIRST_FONT_CHARACTER_INDEX}, fontFamily: _kFontFam, fontPackage: _kFontPkg);\n""")

        f.write("""}\n""")