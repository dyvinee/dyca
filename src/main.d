module main;

import std.stdio;
import std.file;
import std.path;
import core.engine;

void main(string[] args) {
    if (args.length < 2) {
        stderr.writeln("Usage: dyca <file.dyca>");
        return;
    }

    string filePath = args[1];
    
    auto engine = new DycaEngine();
    
    try {
        engine.runFile(filePath);
    } catch (Exception e) {
        stderr.writeln("Error: ", e.msg);
    }
}