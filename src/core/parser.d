module core.parser;

import std.array : array;
import std.algorithm : map;
import std.exception : enforce;
import std.format : format;
import std.conv : to;
import syntax.token : Token, TokenType;
import core.ast : Program, Statement, Expression, LetStatement, ReturnStatement,
                  ExpressionStatement, BlockStatement, Identifier, IntegerLiteral,
                  BooleanLiteral, PrefixExpression, InfixExpression, IfExpression,
                  FunctionLiteral, CallExpression, ImportStatement, ExportStatement,
                  StringLiteral, ArrayLiteral, IndexExpression;
import core.lexer : Lexer;


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
        
        registerPrefix(TokenType.IDENT, "parseIdentifier");
        registerPrefix(TokenType.INT, "parseIntegerLiteral");
        registerPrefix(TokenType.TRUE, "parseBooleanLiteral");
        registerPrefix(TokenType.FALSE, "parseBooleanLiteral");
        registerPrefix(TokenType.BANG, "parsePrefixExpression");
        registerPrefix(TokenType.MINUS, "parsePrefixExpression");
        registerPrefix(TokenType.LPAREN, "parseGroupedExpression");
        registerPrefix(TokenType.IF, "parseIfExpression");
        registerPrefix(TokenType.FUNCTION, "parseFunctionLiteral");
        registerPrefix(TokenType.STRING, "parseStringLiteral");
        registerPrefix(TokenType.LBRACKET, "parseArrayLiteral");
        
        registerInfix(TokenType.PLUS, "parseInfixExpression");
        registerInfix(TokenType.MINUS, "parseInfixExpression");
        registerInfix(TokenType.SLASH, "parseInfixExpression");
        registerInfix(TokenType.ASTERISK, "parseInfixExpression");
        registerInfix(TokenType.EQ, "parseInfixExpression");
        registerInfix(TokenType.NOT_EQ, "parseInfixExpression");
        registerInfix(TokenType.LT, "parseInfixExpression");
        registerInfix(TokenType.GT, "parseInfixExpression");
        registerInfix(TokenType.LPAREN, "parseCallExpression");
        registerInfix(TokenType.LBRACKET, "parseIndexExpression");
        
        nextToken();
        nextToken();
    }
    
    void registerPrefix(TokenType tokenType, string fn) {
        prefixParseFns[tokenType] = fn;
    }
    
    void registerInfix(TokenType tokenType, string fn) {
        infixParseFns[tokenType] = fn;
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
        LetStatement stmt = new LetStatement(curToken);
        
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
        ReturnStatement stmt = new ReturnStatement(curToken);
        
        nextToken();
        
        stmt.returnValue = parseExpression(LOWEST);
        
        if (peekTokenIs(TokenType.SEMICOLON)) {
            nextToken();
        }
        
        return stmt;
    }
    
    ImportStatement parseImportStatement() {
        ImportStatement stmt = new ImportStatement(curToken);
        
        if (!expectPeek(TokenType.IDENT)) {
            return null;
        }
        
        stmt.path = parseIdentifierPath();
        
        if (peekTokenIs(TokenType.AS)) {
            nextToken();
            if (!expectPeek(TokenType.IDENT)) {
                return null;
            }
            stmt.alias_ = curToken.literal;
        }
        
        if (!expectPeek(TokenType.SEMICOLON)) {
            return null;
        }
        
        return stmt;
    }
    
    string[] parseIdentifierPath() {
        string[] path;
        path ~= curToken.literal;
        
        while (peekTokenIs(TokenType.DOT)) {
            nextToken();
            if (!expectPeek(TokenType.IDENT)) {
                return null;
            }
            path ~= curToken.literal;
        }
        
        return path;
    }
    
    ExpressionStatement parseExpressionStatement() {
        ExpressionStatement stmt = new ExpressionStatement(curToken);
        
        stmt.expression = parseExpression(LOWEST);
        
        if (peekTokenIs(TokenType.SEMICOLON)) {
            nextToken();
        }
        
        return stmt;
    }
    
    BlockStatement parseBlockStatement() {
        BlockStatement block = new BlockStatement(curToken);
        
        nextToken();
        
        while (!curTokenIs(TokenType.RBRACE) && !curTokenIs(TokenType.EOF)) {
            Statement stmt = parseStatement();
            if (stmt !is null) {
                block.statements ~= stmt;
            }
            nextToken();
        }
        
        return block;
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
    
    Expression parseIdentifier() {
        return new Identifier(curToken, curToken.literal);
    }
    
    Expression parseIntegerLiteral() {
        IntegerLiteral lit = new IntegerLiteral(curToken);
        
        try {
            lit.value = to!long(curToken.literal);
        } catch (Exception e) {
            errors ~= format("could not parse %s as integer", curToken.literal);
            return null;
        }
        
        return lit;
    }
    
    Expression parseBooleanLiteral() {
        return new BooleanLiteral(curToken, curTokenIs(TokenType.TRUE));
    }
    
    Expression parseStringLiteral() {
        return new StringLiteral(curToken, curToken.literal);
    }
    
    Expression parseArrayLiteral() {
        ArrayLiteral array = new ArrayLiteral(curToken);
        array.elements = parseExpressionList(TokenType.RBRACKET);
        return array;
    }
    
    Expression[] parseExpressionList(TokenType end) {
        Expression[] list;
        
        if (peekTokenIs(end)) {
            nextToken();
            return list;
        }
        
        nextToken();
        list ~= parseExpression(LOWEST);
        
        while (peekTokenIs(TokenType.COMMA)) {
            nextToken();
            nextToken();
            list ~= parseExpression(LOWEST);
        }
        
        if (!expectPeek(end)) {
            return null;
        }
        
        return list;
    }
    
    Expression parsePrefixExpression() {
        PrefixExpression expression = new PrefixExpression(curToken, curToken.literal);
        
        nextToken();
        
        expression.right = parseExpression(PREFIX);
        
        return expression;
    }
    
    Expression parseInfixExpression(Expression left) {
        InfixExpression expression = new InfixExpression(curToken, left, curToken.literal);
        
        Precedence precedence = curPrecedence();
        nextToken();
        expression.right = parseExpression(precedence);
        
        return expression;
    }
    
    Expression parseGroupedExpression() {
        nextToken();
        
        Expression exp = parseExpression(LOWEST);
        
        if (!expectPeek(TokenType.RPAREN)) {
            return null;
        }
        
        return exp;
    }
    
    Expression parseIfExpression() {
        IfExpression expression = new IfExpression(curToken);
        
        if (!expectPeek(TokenType.LPAREN)) {
            return null;
        }
        
        nextToken();
        expression.condition = parseExpression(LOWEST);
        
        if (!expectPeek(TokenType.RPAREN)) {
            return null;
        }
        
        if (!expectPeek(TokenType.LBRACE)) {
            return null;
        }
        
        expression.consequence = parseBlockStatement();
        
        if (peekTokenIs(TokenType.ELSE)) {
            nextToken();
            
            if (!expectPeek(TokenType.LBRACE)) {
                return null;
            }
            
            expression.alternative = parseBlockStatement();
        }
        
        return expression;
    }
    
    Expression parseFunctionLiteral() {
        FunctionLiteral lit = new FunctionLiteral(curToken);
        
        if (!expectPeek(TokenType.LPAREN)) {
            return null;
        }
        
        lit.parameters = parseFunctionParameters();
        
        if (!expectPeek(TokenType.LBRACE)) {
            return null;
        }
        
        lit.body = parseBlockStatement();
        
        return lit;
    }
    
    Identifier[] parseFunctionParameters() {
        Identifier[] identifiers;
        
        if (peekTokenIs(TokenType.RPAREN)) {
            nextToken();
            return identifiers;
        }
        
        nextToken();
        
        Identifier ident = new Identifier(curToken, curToken.literal);
        identifiers ~= ident;
        
        while (peekTokenIs(TokenType.COMMA)) {
            nextToken();
            nextToken();
            ident = new Identifier(curToken, curToken.literal);
            identifiers ~= ident;
        }
        
        if (!expectPeek(TokenType.RPAREN)) {
            return null;
        }
        
        return identifiers;
    }
    
    Expression parseCallExpression(Expression func) {
        auto exp = new CallExpression(curToken, func);
        exp.arguments = parseExpressionList(TokenType.RPAREN);
        return exp;
    }
    
    Expression parseIndexExpression(Expression left) {
        IndexExpression exp = new IndexExpression(curToken, left);
        
        nextToken();
        exp.index = parseExpression(LOWEST);
        
        if (!expectPeek(TokenType.RBRACKET)) {
            return null;
        }
        
        return exp;
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
        string msg = format("expected next token to be %s, got %s instead",
                           t, peekToken.type);
        errors ~= msg;
    }
    
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
        TokenType.EQ: Precedence.EQUALS,
        TokenType.NOT_EQ: Precedence.EQUALS,
        TokenType.LT: Precedence.LESSGREATER,
        TokenType.GT: Precedence.LESSGREATER,
        TokenType.PLUS: Precedence.SUM,
        TokenType.MINUS: Precedence.SUM,
        TokenType.SLASH: Precedence.PRODUCT,
        TokenType.ASTERISK: Precedence.PRODUCT,
        TokenType.LPAREN: Precedence.CALL,
        TokenType.LBRACKET: Precedence.INDEX
    ];
}