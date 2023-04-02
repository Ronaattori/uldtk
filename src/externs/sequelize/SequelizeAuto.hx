// Source: https://www.npmjs.com/package/sequelize-auto
package sequelize;
import js.lib.Promise;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import js.lib.Object;
import sequelize.Sequelize;

@:jsRequire("sequelize-auto")
extern class SequelizeAuto {
    function new(sequelize:Sequelize, username:Null<String>, password:Null<String>, options:EitherType<Object, DynamicAccess<Dynamic>>);
    public function run(): Promise<Dynamic>;
}
