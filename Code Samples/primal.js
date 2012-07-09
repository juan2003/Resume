//Primal.js
(function() {
	var Prime = new PrimeSingleton();
	window.isPrime = Prime.getPrimeTest();
	function PrimeSingleton() {
		var primes = [2,3];
		var topNonPrime = 4;
		this.getPrimeTest = function() { return isPrimeExt; };
		
		function isPrimeExt(n) {
			if ( i < 2 || Math.floor(n) != n  ) return false;
			return isPrime(n);
		}
		function isPrime(n) {
			var i, a = topNonPrime(), max = null,min = null;
			if ( a > n ) {
				max = primes.length-1;
				min = 0;
				while (max != min ){
					i = Math.floor( (max + min)/2 );
					a = primes[i];
					if( a == n ) return true;
					else if ( a > n ) max = i-1;
					else min = i+1;
				}
				return primes[max] == n;
			}
			max = Math.floor( Math.sqrt(i) );
			buildPrimesTo(max);
			i=0;
			do {
				a = primes[i++];
				if (n%a == 0) return false;
			} while (a<=max);
			return true;
		}
		function getTopPrime() {
			return primes[primes.length-1];
		}
		function buildPrimesTo(n) {
			var a = topNonPrime, num = {}, i, f, j, b, x = Math.floor(Math.sqrt(n));
			if ( a >= n ) return;
			for(i=a+1; i<=n; i++){
				num[i] = true;
			}
			for(i=0; i<primes.length; i++){
				for( f in num ){
					a = parseInt(f);
					break;
				}
				f = primes[i];
				if ( f>x ) break;
				while( a % f > 0) a++;
				while ( a<=n ){
					if( a in num ) delete num[a];
					a+=f;
				}
				for( j in num ){
					b = parseInt(j);
					if( b < f*f ) {
						primes.push(b);
						delete num[j];
					}
				}
			}
			for( f in num ){
				primes.push( parseInt(f) );
			}
			topNonPrime = n;
		}
	}
})();