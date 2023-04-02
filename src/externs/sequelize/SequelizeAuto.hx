// Source: https://www.npmjs.com/package/sequelize-auto
package sequelize;
import js.lib.Promise;
import sequelize.Sequelize;

@:jsRequire("sequelize-auto")
extern class SequelizeAuto {
    function new(sequelize:Sequelize, username:Null<String>, password:Null<String>, options:Options);
    public function run(): Promise<Dynamic>;
}

typedef Options = {
    var ?host : String;
    var ?dialect : String;
    var ?directory : String;
    var ?port : String;
    var ?caseModel : String;
    var ?caseFile : String;
    var ?caseProp : String;
    var ?lang : String;
    var ?singularize: String;
    var ?noWrite : Bool;
}
