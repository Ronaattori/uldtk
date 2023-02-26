// Source: https://www.npmjs.com/package/sequelize
package sequelize;
import haxe.extern.EitherType;
import js.lib.Object;

@:jsRequire("sequelize")
extern class Sequelize {
    function new(type:EitherType<String, Object>);

	public function define(name:String, definition:Object): Model;
    public function showAllSchemas(): Sequelize;
    public function query(query:String): js.lib.Promise<Dynamic>;
}

@:jsRequire("sequelize")
extern class Model {
    public function sync():Void;
}

@:jsRequire("sequelize")
extern class DataTypes {
    static public var STRING: DataTypes;
    function new();
}

