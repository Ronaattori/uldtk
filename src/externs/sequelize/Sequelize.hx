// Source: https://www.npmjs.com/package/sequelize
package sequelize;
import haxe.Json;
import js.lib.Promise;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import js.lib.Object;
import sequelize.SequelizeAuto.SequelizeAuto;

@:jsRequire("sequelize")
extern class Sequelize {
    function new(type:EitherType<String, SequelizeOptions>);
    public var models:DynamicAccess<Model>;
    public var options:DynamicAccess<Dynamic>;

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
    public function findAll(?options:QueryOptions):Promise<Dynamic>;
    public function findByPk(value:Dynamic):Promise<Model>;
    public var name:String;
    public var primaryKeyAttribute:String;
}

@:jsRequire("sequelize")
extern class DataTypes {
    static public var STRING: DataTypes;
    function new();
}

function initializeSequelize(project:data.Project, sequelize:Sequelize):Void {
    var levelDir = project.getAbsExternalFilesDir();
	var sequelize = new Sequelize({
		dialect: "sqlite",
		storage: levelDir + "/database.sqlite",
		define: {
			freezeTableName: true,
		}
	});
    // SequelizeAuto.run() closes the database connection, so we create a temp connection for the schema creation
    var tmp_sequelize = new Sequelize({
		dialect: "sqlite",
		storage: sequelize.options.get("storage"),
    });
    var auto = new SequelizeAuto(tmp_sequelize, null, null, {noWrite: true, caseFile: "l", caseModel: "p", caseProp: "c"});
    auto.run().then((data:DynamicAccess<Dynamic>) -> {
        var tables:DynamicAccess<Dynamic> = data.get("tables");
        for (tableName in tables.keys()) {
            var table = tables[tableName];
            sequelize.define(tableName, table);
        }
        project.sequelize = sequelize;
    });
};

typedef SequelizeOptions = {
    var ?dialect : String;
    var ?storage: String;
    var ?define : Dynamic;
}
typedef QueryOptions = {
    var ?where : Dynamic;
    var ?attributes : Dynamic;
    var ?order : Dynamic;
    var ?raw : Bool;
}