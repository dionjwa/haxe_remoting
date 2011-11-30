package ;

using Lambda;

class AsyncLambda
{
	/**
	  * Asynchronously calls f on the elements of it.  f takes a finish callback for that element, where the argument 
	  * is an error or null if called successfull.
	  */
	public static function iter<T> (it :Iterable<T>, f :T->(Void->Void)->Void, onFinish :Dynamic->Void) :Void
	{
		var iterator = it.iterator();
		var asyncCall = null;
		asyncCall = function () :Void {
			if (iterator.hasNext()) {
				try {
					f(iterator.next(), asyncCall);
				} catch (err :Dynamic) {
					onFinish(err);	
				}
			} else {
				onFinish(null);
			}
		}
		asyncCall();
	}
}
