module core.ast;

import syntax.token : Token;

interface Node {
    string tokenLiteral();
}

interface Statement : Node {
    void statementNode();
}

interface Expression : Node {
    void expressionNode();
}

class Program {
    Statement[] statements;
    
    string tokenLiteral() {
        if (statements.length > 0) {
            return statements[0].tokenLiteral();
        }
        return "";
    }
}

class Identifier : Expression {
    Token token;
    string value;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class ImportStatement : Statement {
    Token token;
    string[] path;
    string alias;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class ExportStatement : Statement {
    Token token;
    string[] path;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class BlockStatement : Statement {
    Token token;
    Statement[] statements;
    
    void statementNode() {}
    string tokenLiteral() { return token.literal; }
}

class FunctionLiteral : Expression {
    Token token;
    Identifier[] parameters;
    BlockStatement body;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class CallExpression : Expression {
    Token token;
    Expression function;
    Expression[] arguments;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class IfExpression : Expression {
    Token token;
    Expression condition;
    BlockStatement consequence;
    BlockStatement alternative;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}

class ForExpression : Expression {
    Token token;
    Statement init;
    Expression condition;
    Statement update;
    BlockStatement body;
    
    void expressionNode() {}
    string tokenLiteral() { return token.literal; }
}