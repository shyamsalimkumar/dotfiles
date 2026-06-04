# When to Mock

Mock at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases (sometimes - prefer test DB)
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally.

### TypeScript

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

### Go

In Go, define a narrow interface at the point of use — not in the package that implements it.

```go
// Easy to mock: accept an interface
type PaymentClient interface {
    Charge(amount int64) error
}

func ProcessPayment(order Order, client PaymentClient) error {
    return client.Charge(order.Total)
}

// Hard to mock: construct the concrete type internally
func ProcessPayment(order Order) error {
    client := stripe.NewClient(os.Getenv("STRIPE_KEY"))
    return client.Charge(order.Total)
}

// In tests: implement the interface inline
type fakePaymentClient struct {
    charged int64
    err     error
}

func (f *fakePaymentClient) Charge(amount int64) error {
    f.charged = amount
    return f.err
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic.

### TypeScript

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

### Go

```go
// GOOD: narrow interface per concern — each method is independently fakeable
type UserStore interface {
    GetUser(ctx context.Context, id string) (User, error)
    CreateUser(ctx context.Context, name string) (User, error)
}

type OrderStore interface {
    GetOrders(ctx context.Context, userID string) ([]Order, error)
    CreateOrder(ctx context.Context, data OrderInput) (Order, error)
}

// BAD: one wide interface forces every fake to implement everything
type Store interface {
    Query(ctx context.Context, query string, args ...any) (*sql.Rows, error)
}
```

The SDK / narrow-interface approach means:

- Each fake returns one specific shape
- No conditional logic in test setup
- Easier to see which operations a test exercises
- Compiler enforces the contract
