module utils.file;

import std.file;
import std.path;
import std.string;
import core.ast;
import core.parser;
import core.engine;

class ModuleLoader {
    static Program loadModule(string[] path, string basePath) {
        string filePath = buildPath(basePath, buildPath(path));
        filePath ~= ".dyca";
        
        if (!exists(filePath)) {
            throw new Exception("Module not found: " ~ filePath);
        }
        
        string source = readText(filePath);
        Lexer lexer = new Lexer(source);
        Parser parser = new Parser(lexer);
        Program program = parser.parseProgram();
        
        if (parser.errors.length > 0) {
            throw new Exception("Parser errors in module: " ~ filePath ~ "\n" ~ 
                join(parser.errors, "\n"));
        }
        
        return program;
    }
}