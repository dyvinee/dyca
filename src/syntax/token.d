module syntax.token;

import std.conv : to;

enum TokenType {
    ILLEGAL,
    EOF,
    
    // Identifiers + literals
    IDENT,
    INT,
    STRING,
    
    // Operators
    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,
    LT,
    GT,
    EQ,
    NOT_EQ,
    
    // Delimiters
    COMMA,
    SEMICOLON,
    COLON,
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,
    LBRACKET,
    RBRACKET,
    DOT,
    
    // Keywords
    FUNCTION,
    LET,
    IF,
    ELSE,
    RETURN,
    IMPORT,
    EXPORT,
    AS,
    TRUE,
    FALSE,
    NULL
}

class Token {
    TokenType type;
    string literal;
    
    this(TokenType type, string literal) {
        this.type = type;
        this.literal = literal;
    }
    
    override string toString() {
        return `Token(type: ` ~ type.to!string ~ `, literal: "` ~ literal ~ `")`;
    }
}

TokenType fromString(string s) {
    switch (s) {
        case "function": return TokenType.FUNCTION;
        case "if": return TokenType.IF;
        case "else": return TokenType.ELSE;
        case "return": return TokenType.RETURN;
        case "import": return TokenType.IMPORT;
        case "export": return TokenType.EXPORT;
        case "true": return TokenType.TRUE;
        case "false": return TokenType.FALSE;
        case "null": return TokenType.NULL;
        default: return TokenType.ILLEGAL;
    }
}