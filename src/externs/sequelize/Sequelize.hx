// Source: https://www.npmjs.com/package/sequelize
package sequelize;
import haxe.Json;
import js.lib.Promise;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import js.lib.Object;

@:jsRequire("sequelize")
extern class Sequelize {
    function new(type:EitherType<String, Object>);
    public var models:DynamicAccess<Model>;

	public function define(name:String, definition:EitherType<Object, DynamicAccess<Dynamic>>): Model;
    public function showAllSchemas(): Sequelize;
    public function query(query:String): js.lib.Promise<Dynamic>;
}

@:jsRequire("sequelize")
extern class Model {
    public function sync():Promise<Model>;
    public function toJSON():Json;
    public function create(data:EitherType<Object, DynamicAccess<Dynamic>>):Model;
    public function bulkCreate(data:Array<EitherType<Object, DynamicAccess<Dynamic>>>):Model;
    public function findAll():Promise<Dynamic>;
    public function findByPk(value:Dynamic):Promise<Model>;
    public var name:String;
}

@:jsRequire("sequelize")
extern class DataTypes {
    static public var STRING: DataTypes;
    function new();
}

function initialize(sequelize:Sequelize):Void {
    sequelize.query("SELECT * FROM sqlite_master").then((r:Array<Array<DynamicAccess<String>>>) -> {
        // r[0] is a list of tables. r[1] is an empty object?
        for (table in r[0]) {
            if (table.get("type") != "table") continue;
            var definition:DynamicAccess<Dynamic> = {};
            var reg = ~/\((.*)\)/i;
            reg.match(table.get("sql"));
            var data = reg.matched(1);

            var columns = data.split(", ");
            columns.splice(columns.length-2, 2); // Remove Sequelites own "createdAt" and "updatedAt" columns
            for (column in columns) {
                var col:DynamicAccess<Dynamic> = {};

                var n = ~/`(.*)`/i;
                n.match(column);
                var name = n.matched(1);
                
                var datatype = column.split(" ")[1];
                switch datatype {
                    case "VARCHAR(255)":
                        col.set("type", DataTypes.STRING);
                    // TODO add datatypes when I support creating anything other than string
                    
                }
                if (~/PRIMARY KEY/i.match(column)) col.set("primaryKey", true);
                if (~/NOT NULL/i.match(column)) col.set("allowNull", false);

                definition.set(name, col);
            }
            sequelize.define(table.get("name"), definition);
        }
    });
};
