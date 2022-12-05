module RenderReact
  COMPONENT_MAPPING = {
    'vendor/blog_posts/index' => 'BlogPostListPage',
    'vendor/blog_posts/show' => 'BlogPostPage',
    'vendor/cabinet/show' => 'CabinetPage',
    'vendor/cart/show' => 'CartPage',
    'vendor/categories/show' => 'CategoriesShowPage',
    'vendor/categories/show_children' => 'CategoriesShowChildrenPage',
    'vendor/client_registration/new' => 'ClientRegistrationPage',
    'vendor/client_reset_passwords/show' => 'ClientResetPasswordPage',
    'vendor/client_restore_password/show' => 'ClientRestorePasswordPage',
    'vendor/client_sessions/new' => 'ClientSessionNewPage',
    'vendor/content_pages/show' => 'ContentPagePage',
    'vendor/dictionary_entities/show' => 'DictionaryEntitiesShowPage',
    'vendor/lookbooks/show' => 'LookbookPage',
    'vendor/orders/canceled' => 'OrderCancelledPage',
    'vendor/orders/created' => 'OrderCreatedPage',
    'vendor/orders/new' => 'OrderPage',
    'vendor/orders/paid' => 'OrderPaidPage',
    'vendor/orders/payment' => 'OrderPaymentPage',
    'vendor/orders/show' => 'OrderShowPage',
    'vendor/products/archived' => 'ProductArchivedPage',
    'vendor/products/search' => 'ProductSearchPage',
    'vendor/products/show' => 'ProductCardPage',
    'vendor/welcome/index' => 'WelcomePage',
    'vendor/welcome/index_children' => 'WelcomeChildrenPage',
    'vendor/wishlist/show' => 'WishlistPage',
    'vendor/payment/show' => 'PaymentPage',
    'vendor/base/not_found' => 'ErrorPagePage'
  }.freeze

  def render_react(template, props:, layout:, status:, formats:)
    component = COMPONENT_MAPPING[template] || raise("Unknown component for template #{template}")

    props = props.merge(common_props)
    render component: component, props: props, layout: layout, status: status, formats: formats
  rescue StandardError => e
    Bugsnag.notify e, metaData: { component: component, error_class: e.class, props: props }

    raise e
  end
end
