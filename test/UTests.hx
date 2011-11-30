package ;

import utest.Assert;
import utest.Runner;
import utest.ui.Report;

class UTests
{
	public static function main () :Void
	{
		var runner = new Runner();
		runner.addCase(new serialization.SerializationTest());
		runner.addCase(new remoting.BuildTest());
		Report.create(runner);
		runner.run();
	}
}
