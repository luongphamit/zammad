org_community = Organization.create_if_not_exists(
  id: 1,
  name: 'Khonet',
)
user_community = User.create_or_update(
  id: 2,
  login: 'info@khonet.com',
  firstname: 'Khonet',
  lastname: 'Info',
  email: 'info@khonet.com',
  password: '',
  active: true,
  roles: [ Role.find_by(name: 'Customer') ],
  organization_id: org_community.id,
)

UserInfo.current_user_id = user_community.id

ticket = Ticket.create!(
  group_id: Group.find_by(name: 'Users').id,
  customer_id: User.find_by(login: 'info@khonet.com').id,
  title: 'Welcome to Epfen uCare!',
)
Ticket::Article.create!(
  ticket_id: ticket.id,
  type_id: Ticket::Article::Type.find_by(name: 'phone').id,
  sender_id: Ticket::Article::Sender.find_by(name: 'Customer').id,
  from: 'Epfen uCare <ucare@epfen.com>',
  body: 'Welcome!

Thank you for choosing Epfen uCare.

You will find updates and patches at https://epfen.com/. Online
documentation is available at https://docs.epfen.com.

Regards,

Epfen uCare Team
',
  internal: false,
)

UserInfo.current_user_id = 1
