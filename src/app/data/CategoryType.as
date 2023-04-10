package app.data
{
	public final class CategoryType
	{
		public static const Transformice	: CategoryType = new CategoryType(100);
		public static const House			: CategoryType = new CategoryType(300);
		public static const Autumn			: CategoryType = new CategoryType(400);
		public static const Winter			: CategoryType = new CategoryType(500);
		public static const Valentines		: CategoryType = new CategoryType(900);
		public static const Sea				: CategoryType = new CategoryType(150);
		public static const Spring			: CategoryType = new CategoryType(600);
		public static const Various			: CategoryType = new CategoryType(1000);
		
		public static const ALL : Vector.<CategoryType> = new <CategoryType>[
			Transformice, House, Autumn, Winter, Valentines, Sea, Spring, Various];
		
		// Enum Storage + Constructor
		private var _value: int;
		function CategoryType(catID:int) { _value = catID; }
		
		// This is required for proper auto string convertion on `trace`/`Dictionary` and such - enums should always have
		public function toString() : String { return "CatPicto_" + _value.toString(); }
		
		public function toInt() : int { return _value; }
	}
}
