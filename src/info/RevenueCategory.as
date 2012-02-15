package info
{
	public class RevenueCategory
	{
		protected var _category:Object = new Object();
		
		public function RevenueCategory()
		{
			_category['customs duties'] = 'Taxes on imports, paid by the importer.';
			_category['excise taxes'] = 'Taxes on particular goods, like gasoline or cigarettes.';
			_category['payroll taxes'] = 'Taxes paid by workers and employers that directly fund the Social Security and Medicare programs. They are calculated as a percent of wages and salaries.';
			_category['corporate income taxes'] = 'Income taxes paid by corporations.';
			_category['individual income taxes'] = 'Income taxes paid by individuals and families. Income taxes are calculated as a percent of wages and other kinds of income.';
			_category['other'] = 'Miscellaneous government revenues as well as estate and gift taxes.';
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