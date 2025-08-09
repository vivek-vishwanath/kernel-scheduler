int multiply(int a, int b) {
	int product = 0;
	int mask = 1;
	for (int i = 0; i < 32; i++) {
		if (b & mask) {
			product += a;
		}
		a <<= 1;
		mask <<= 1;
	}
	return product;
}

int factorial(int a) {
    if (a < 0) return -1;
    if (a < 2) return 1;
    return multiply(a, factorial(a - 1));
}

void main() {
    volatile int result = factorial(10);
}