package info
{
	public class BudgetCategory
	{
		protected var _category:Object = new Object();
		
		public function BudgetCategory()
		{
			_category['education'] = 'Elementary, secondary, vocational, and higher education.';
			_category['energy & environment'] = 'Energy supply, energy use, and natural resource conservation.';
			_category['food & agriculture'] = 'Agriculture research, support to the agriculture industry, and food assistance programs. Food assistance includes food stamps, WIC, the school lunch program, among others.';
			_category['government'] = 'Judicial, executive, and legislative branches of government, as well as the postal service.';
			_category['housing & community'] = 'Housing assistance, community development, and disaster assistance and relief.';
			_category['interest on debt'] = 'The interest payments the federal government makes on its accumulated debt minus interest income received by the government for assets it owns.';
			_category['international affairs'] = 'Diplomacy, and development and humanitarian activities overseas.';
			_category['medicare & health'] = 'Medicare, Medicaid, Children’s Health Insurance Program, as well as consumer and occupational health and safety.';
			_category['military'] = 'Military, war costs, nuclear weapons, and international security.';
			_category['science'] = 'Scientific research.';
			_category['social security & labor'] = 'Social Security, Unemployment Insurance, job training, and federal employee retirement and disability programs.';
			_category['transportation'] = 'Air, water, and ground transportation.';
			_category['veterans benefits'] = 'Health care, housing, education, and income benefits for veterans.';
			_category['other'] = 'Scientific research, transportation, international affairs, and government.';
		}
		
		public function getCategory(s:String):String {
			var desc:String = new String();
			for (var key:Object in _category) {
				if (key === s) {
					desc = _category[s];
				}
			}
			return desc;
		}
	}
}