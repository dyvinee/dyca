module core.lexer;

import std.conv : to;
import std.array : appender;
import std.algorithm : find;
import std.ascii : isDigit, isAlpha, isWhite;
import std.string : strip;
import std.algorithm : canFind;
import syntax.token : Token, TokenType;

class Lexer {
    string input;
    size_t position;
    size_t readPosition;
    char ch;
    string[] keywords = [
        "function", "if", "else", "return", 
        "import", "export", "true", "false", "null",
        "for", "as"
    ];

    this(string input) {
        this.input = input;
        readChar();
    }

    void readChar() {
        if (readPosition >= input.length) {
            ch = 0;
        } else {
            ch = input[readPosition];
        }
        position = readPosition;
        readPosition++;
    }

    Token nextToken() {
        Token tok;
        skipWhitespace();

        switch (ch) {
            case '=':
                if (peekChar() == '=') {
                    readChar();
                    tok = new Token(TokenType.EQ, "==");
                } else {
                    tok = new Token(TokenType.ASSIGN, ch.to!string);
                }
                break;
            case ';':
                tok = new Token(TokenType.SEMICOLON, ch.to!string);
                break;
            case '(':
                tok = new Token(TokenType.LPAREN, ch.to!string);
                break;
            case ')':
                tok = new Token(TokenType.RPAREN, ch.to!string);
                break;
            case ',':
                tok = new Token(TokenType.COMMA, ch.to!string);
                break;
            case '+':
                tok = new Token(TokenType.PLUS, ch.to!string);
                break;
            case '-':
                tok = new Token(TokenType.MINUS, ch.to!string);
                break;
            case '!':
                if (peekChar() == '=') {
                    readChar();
                    tok = new Token(TokenType.NOT_EQ, "!=");
                } else {
                    tok = new Token(TokenType.BANG, ch.to!string);
                }
                break;
            case '/':
                tok = new Token(TokenType.SLASH, ch.to!string);
                break;
            case '*':
                tok = new Token(TokenType.ASTERISK, ch.to!string);
                break;
            case '<':
                tok = new Token(TokenType.LT, ch.to!string);
                break;
            case '>':
                tok = new Token(TokenType.GT, ch.to!string);
                break;
            case '{':
                tok = new Token(TokenType.LBRACE, ch.to!string);
                break;
            case '}':
                tok = new Token(TokenType.RBRACE, ch.to!string);
                break;
            case '"':
                tok = new Token(TokenType.STRING, readString());
                break;
            case '[':
                tok = new Token(TokenType.LBRACKET, ch.to!string);
                break;
            case ']':
                tok = new Token(TokenType.RBRACKET, ch.to!string);
                break;
            case ':':
                tok = new Token(TokenType.COLON, ch.to!string);
                break;
            case 0:
                tok = new Token(TokenType.EOF, "");
                break;
            default:
                if (isLetter(ch)) {
                    string ident = readIdentifier();
                    TokenType type = lookupIdent(ident);
                    return new Token(type, ident);
                } else if (isDigit(ch)) {
                    return new Token(TokenType.INT, readNumber());
                } else {
                    tok = new Token(TokenType.ILLEGAL, ch.to!string);
                }
        }

        readChar();
        return tok;
    }

    char peekChar() {
        if (readPosition >= input.length) {
            return 0;
        } else {
            return input[readPosition];
        }
    }

    void skipWhitespace() {
        while (isWhite(ch)) {
            readChar();
        }
    }

    string readIdentifier() {
        size_t pos = position;
        while (isLetter(ch)) {
            readChar();
        }
        return input[pos..position];
    }

    string readNumber() {
        size_t pos = position;
        while (isDigit(ch)) {
            readChar();
        }
        return input[pos..position];
    }

    string readString() {
        readChar(); // skip opening quote
        size_t pos = position;
        
        while (ch != '"' && ch != 0) {
            readChar();
        }
        
        string str = input[pos..position];
        readChar(); // skip closing quote
        return str;
    }

    bool isLetter(char c) {
        return c.isAlpha || c == '_' || c == '.';
    }

    bool isKeyword(string ident) {
        return canFind(keywords, ident);
    }

    TokenType lookupIdent(string ident) {
        if (isKeyword(ident)) {
            return TokenType.fromString(ident);
        }
        return TokenType.IDENT;
    }
}