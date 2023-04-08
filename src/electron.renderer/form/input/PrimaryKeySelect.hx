package form.input;

import sequelize.Sequelize.Model;

class PrimaryKeySelect extends form.Input<String> {

	public function new(j:js.jquery.JQuery, m:Model, allowNull=false, getter:Void->String, setter:String->Void) {

		super(j, getter, setter);

		jInput.empty();
		for (k in m.rawAttributes.keys()) {
			var opt = new J("<option/>");
			jInput.append(opt);
			opt.attr("value", k);
			opt.text(k);
			if (k==Std.string(getter())) {
				opt.attr("selected", "selected");
			}
		}
	}
}
