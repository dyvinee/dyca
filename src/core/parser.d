module core.parser;

import std.array : array;
import std.algorithm : map;
import std.exception : enforce;
import std.format : format;
import syntax.token : Token, TokenType;
import core.ast : Program, Statement, Expression, LetStatement, ReturnStatement,
                  ExpressionStatement, BlockStatement, Identifier, IntegerLiteral,
                  BooleanLiteral, PrefixExpression, InfixExpression, IfExpression,
                  FunctionLiteral, CallExpression, ImportStatement, ExportStatement;

class Parser {
    Lexer lexer;
    Token curToken;
    Token peekToken;
    string[] errors;
    
    string[TokenType] prefixParseFns;
    string[TokenType] infixParseFns;
    
    this(Lexer lexer) {
        this.lexer = lexer;
        this.errors = [];
        
        // Initialize prefix parse functions
        prefixParseFns[TokenType.IDENT] = "parseIdentifier";
        prefixParseFns[TokenType.INT] = "parseIntegerLiteral";
        prefixParseFns[TokenType.TRUE] = "parseBooleanLiteral";
        prefixParseFns[TokenType.FALSE] = "parseBooleanLiteral";
        prefixParseFns[TokenType.BANG] = "parsePrefixExpression";
        prefixParseFns[TokenType.MINUS] = "parsePrefixExpression";
        prefixParseFns[TokenType.LPAREN] = "parseGroupedExpression";
        prefixParseFns[TokenType.IF] = "parseIfExpression";
        prefixParseFns[TokenType.FUNCTION] = "parseFunctionLiteral";
        prefixParseFns[TokenType.STRING] = "parseStringLiteral";
        
        // Initialize infix parse functions
        infixParseFns[TokenType.PLUS] = "parseInfixExpression";
        infixParseFns[TokenType.MINUS] = "parseInfixExpression";
        infixParseFns[TokenType.SLASH] = "parseInfixExpression";
        infixParseFns[TokenType.ASTERISK] = "parseInfixExpression";
        infixParseFns[TokenType.EQ] = "parseInfixExpression";
        infixParseFns[TokenType.NOT_EQ] = "parseInfixExpression";
        infixParseFns[TokenType.LT] = "parseInfixExpression";
        infixParseFns[TokenType.GT] = "parseInfixExpression";
        infixParseFns[TokenType.LPAREN] = "parseCallExpression";
        
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
            case TokenType.LET:
                return parseLetStatement();
            case TokenType.RETURN:
                return parseReturnStatement();
            case TokenType.IMPORT:
                return parseImportStatement();
            case TokenType.EXPORT:
                return parseExportStatement();
            default:
                return parseExpressionStatement();
        }
    }
    
    LetStatement parseLetStatement() {
        LetStatement stmt;
        stmt.token = curToken;
        
        if (!expectPeek(TokenType.IDENT)) {
            return null;
        }
        
        stmt.name = new Identifier(curToken, curToken.literal);
        
        if (!expectPeek(TokenType.ASSIGN)) {
            return null;
        }
        
        nextToken();
        
        stmt.value = parseExpression(LOWEST);
        
        if (peekTokenIs(TokenType.SEMICOLON)) {
            nextToken();
        }
        
        return stmt;
    }
    
    ReturnStatement parseReturnStatement() {
        ReturnStatement stmt;
        stmt.token = curToken;
        
        nextToken();
        
        stmt.returnValue = parseExpression(LOWEST);
        
        if (peekTokenIs(TokenType.SEMICOLON)) {
            nextToken();
        }
        
        return stmt;
    }
    
    ExpressionStatement parseExpressionStatement() {
        ExpressionStatement stmt;
        stmt.token = curToken;
        
        stmt.expression = parseExpression(LOWEST);
        
        if (peekTokenIs(TokenType.SEMICOLON)) {
            nextToken();
        }
        
        return stmt;
    }
    
    Expression parseExpression(Precedence precedence) {
        string prefixFn = prefixParseFns.get(curToken.type, null);
        if (prefixFn is null) {
            errors ~= format("no prefix parse function for %s found", curToken.type);
            return null;
        }
        
        Expression leftExp = mixin(prefixFn ~ "()");
        
        while (!peekTokenIs(TokenType.SEMICOLON) && precedence < peekPrecedence()) {
            string infixFn = infixParseFns.get(peekToken.type, null);
            if (infixFn is null) {
                return leftExp;
            }
            
            nextToken();
            leftExp = mixin(infixFn ~ "(leftExp)");
        }
        
        return leftExp;
    }
    
    // ... (other parsing methods remain the same)
    
    enum Precedence {
        LOWEST,
        EQUALS,      // ==
        LESSGREATER, // > or <
        SUM,         // +
        PRODUCT,     // *
        PREFIX,      // -X or !X
        CALL,        // myFunction(X)
        INDEX        // array[index]
    }
    
    Precedence peekPrecedence() {
        return tokenPrecedences.get(peekToken.type, LOWEST);
    }
    
    Precedence curPrecedence() {
        return tokenPrecedences.get(curToken.type, LOWEST);
    }
    
    static Precedence[TokenType] tokenPrecedences = [
        TokenType.EQ: EQUALS,
        TokenType.NOT_EQ: EQUALS,
        TokenType.LT: LESSGREATER,
        TokenType.GT: LESSGREATER,
        TokenType.PLUS: SUM,
        TokenType.MINUS: SUM,
        TokenType.SLASH: PRODUCT,
        TokenType.ASTERISK: PRODUCT,
        TokenType.LPAREN: CALL,
        TokenType.LBRACKET: INDEX
    ];
}