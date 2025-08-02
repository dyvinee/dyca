module main;

import std.stdio;
import std.file;
import std.path;
import core.engine;
import utils.file;

void main(string[] args) {
    if (args.length < 2) {
        stderr.writeln("Usage: dyca <file.dyca>");
        return;
    }

    string filePath = args[1];
    string basePath = dirName(filePath);
    
    auto engine = new DycaEngine();
    
    try {
        // Load main module
        engine.runFile(filePath);
        
        // Handle imports
        // (This would be more sophisticated in a real implementation)
        if (engine.hasPendingImports()) {
            foreach (importPath; engine.getPendingImports()) {
                auto module = ModuleLoader.loadModule(importPath, basePath);
                engine.registerModule(importPath, module);
            }
        }
    } catch (Exception e) {
        stderr.writeln("Error: ", e.msg);
    }
}