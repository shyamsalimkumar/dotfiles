# Good and Bad Tests

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

### TypeScript

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

### Go

```go
// GOOD: Tests observable behavior
func TestCheckout_WithValidCart(t *testing.T) {
    cart := NewCart()
    cart.Add(product)
    result, err := Checkout(cart, paymentMethod)
    require.NoError(t, err)
    assert.Equal(t, "confirmed", result.Status)
}
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

### TypeScript

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

### Go

```go
// BAD: Tests implementation details
func TestCheckout_CallsPaymentService(t *testing.T) {
    mock := &mockPaymentService{}
    checkout(cart, mock)
    assert.True(t, mock.processCalled) // testing HOW, not WHAT
    assert.Equal(t, cart.Total(), mock.processedAmount)
}
```

Red flags:

- Mocking internal collaborators
- Testing private/unexported methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

**Bypassing the interface to verify:**

### TypeScript

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

### Go

```go
// BAD: Bypasses interface to verify
func TestCreateUser_SavesRow(t *testing.T) {
    CreateUser(ctx, "Alice")
    var name string
    db.QueryRow("SELECT name FROM users WHERE name = ?", "Alice").Scan(&name)
    assert.Equal(t, "Alice", name) // verifying storage detail, not behavior
}

// GOOD: Verifies through interface
func TestCreateUser_IsRetrievable(t *testing.T) {
    user, err := CreateUser(ctx, "Alice")
    require.NoError(t, err)
    retrieved, err := GetUser(ctx, user.ID)
    require.NoError(t, err)
    assert.Equal(t, "Alice", retrieved.Name)
}
```

**Tautological tests**: Expected value restates the implementation, so the test passes by construction.

### TypeScript

```typescript
// BAD: Expected value is recomputed the way the code computes it
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: Expected value is an independent, known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```

### Go

```go
// BAD: Expected value is recomputed the way the code computes it
func TestCalculateTotal_SumsLineItems(t *testing.T) {
    items := []Item{{Price: 10}, {Price: 5}}
    var expected int64
    for _, i := range items {
        expected += i.Price
    }
    assert.Equal(t, expected, CalculateTotal(items))
}

// GOOD: Expected value is an independent, known literal
func TestCalculateTotal_SumsLineItems(t *testing.T) {
    items := []Item{{Price: 10}, {Price: 5}}
    assert.Equal(t, int64(15), CalculateTotal(items))
}
```
