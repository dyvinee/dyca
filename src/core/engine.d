module core.engine;

import std.stdio;
import std.file;
import std.path;
import core.lexer;
import core.parser;
import core.eval;
import core.object;
import stdlib.io;

class DycaEngine {
    Environment globalEnv;
    
    this() {
        globalEnv = new Environment();
        // Register built-in functions
        globalEnv.set("print", new PrintFunction());
        globalEnv.set("println", new PrintlnFunction());
        globalEnv.set("input", new InputFunction());
    }
    
    void runFile(string filePath) {
        string input = readText(filePath);
        run(input, buildPath(dirName(filePath)));
    }
    
    void run(string input, string basePath = "") {
        Lexer lexer = new Lexer(input);
        Parser parser = new Parser(lexer);
        Program program = parser.parseProgram();
        
        if (parser.errors.length > 0) {
            printParserErrors(parser.errors);
            return;
        }
        
        Object evaluated = Evaluator.eval(program, globalEnv);
        if (evaluated !is null && evaluated.objectType() == "ERROR") {
            writeln(evaluated.inspect());
        }
    }
    
    private void printParserErrors(string[] errors) {
        writeln("Parser errors:");
        foreach (error; errors) {
            writeln("\t", error);
        }
    }
}