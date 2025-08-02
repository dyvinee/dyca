module core.parser;

import std.array : array;
import std.algorithm : map;
import std.exception : enforce;
import syntax.token : Token, TokenType;
import core.ast : {
    Program, Statement, Expression, 
    ImportStatement, ExportStatement,
    BlockStatement, FunctionLiteral,
    Identifier, CallExpression,
    IfExpression, ForExpression
};

class Parser {
    Lexer lexer;
    Token curToken;
    Token peekToken;
    string[] errors;
    
    this(Lexer lexer) {
        this.lexer = lexer;
        this.errors = [];
        
        // Read two tokens to initialize curToken and peekToken
        nextToken();
        nextToken();
    }
    
    void nextToken() {
        curToken = peekToken;
        peekToken = lexer.nextToken();
    }
    
    Program parseProgram() {
        Program program;
        
        while (curToken.type != TokenType.EOF) {
            Statement stmt = parseStatement();
            if (stmt !is null) {
                program.statements ~= stmt;
            }
            nextToken();
        }
        
        return program;
    }
    
    Statement parseStatement() {
        switch (curToken.type) {
            case TokenType.IMPORT:
                return parseImportStatement();
            case TokenType.EXPORT:
                return parseExportStatement();
            case TokenType.FUNCTION:
                return parseFunctionStatement();
            default:
                return parseExpressionStatement();
        }
    }
    
    ImportStatement parseImportStatement() {
        ImportStatement stmt;
        stmt.token = curToken;
        
        enforce(expectPeek(TokenType.IDENT), "Expected identifier after import");
        
        stmt.path = parseIdentifierPath();
        
        if (peekTokenIs(TokenType.AS)) {
            nextToken();
            enforce(expectPeek(TokenType.IDENT), "Expected identifier after as");
            stmt.alias = curToken.literal;
        }
        
        enforce(expectPeek(TokenType.SEMICOLON), "Expected semicolon after import statement");
        
        return stmt;
    }
    
    string[] parseIdentifierPath() {
        string[] path;
        path ~= curToken.literal;
        
        while (peekTokenIs(TokenType.DOT)) {
            nextToken();
            enforce(expectPeek(TokenType.IDENT), "Expected identifier after dot");
            path ~= curToken.literal;
        }
        
        return path;
    }
    
    bool curTokenIs(TokenType t) {
        return curToken.type == t;
    }
    
    bool peekTokenIs(TokenType t) {
        return peekToken.type == t;
    }
    
    bool expectPeek(TokenType t) {
        if (peekTokenIs(t)) {
            nextToken();
            return true;
        } else {
            peekError(t);
            return false;
        }
    }
    
    void peekError(TokenType t) {
        string msg = format("Expected next token to be %s, got %s instead",
                            t, peekToken.type);
        errors ~= msg;
    }
    
    // Additional parser methods would go here...
}