# encoding: utf-8
require 'test_helper'

class ObjectManagerTest < ActiveSupport::TestCase
  test 'a object manager' do

    list_objects = ObjectManager.list_objects
    assert_equal(%w(Ticket TicketArticle User Organization Group), list_objects)

    list_objects = ObjectManager.list_frontend_objects
    assert_equal(%w(Ticket User Organization Group), list_objects)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    # create simple attribute
    attribute1 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'test1',
      display: 'Test 1',
      data_type: 'input',
      data_option: {
        maxlength: 200,
        type: 'text',
        null: false,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
      editable: false,
      to_migrate: false,
    )
    assert(attribute1)
    assert_equal('test1', attribute1.name)
    assert_equal(true, attribute1.editable)
    assert_equal(true, attribute1.to_create)
    assert_equal(true, attribute1.to_migrate)
    assert_equal(false, attribute1.to_delete)
    assert_equal(true, ObjectManager::Attribute.pending_migration?)

    attribute1 = ObjectManager::Attribute.get(
      object: 'Ticket',
      name: 'test1',
    )
    assert(attribute1)
    assert_equal('test1', attribute1.name)
    assert_equal(true, attribute1.editable)
    assert_equal(true, attribute1.to_create)
    assert_equal(true, attribute1.to_migrate)
    assert_equal(false, attribute1.to_delete)
    assert_equal(true, ObjectManager::Attribute.pending_migration?)

    # delete attribute without execute migrations
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'test1',
    )

    attribute1 = ObjectManager::Attribute.get(
      object: 'Ticket',
      name: 'test1',
    )
    assert_not(attribute1)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert(ObjectManager::Attribute.migration_execute)

    attribute1 = ObjectManager::Attribute.get(
      object: 'Ticket',
      name: 'test1',
    )
    assert_not(attribute1)

    # create invalid attributes
    assert_raises(RuntimeError) {
      attribute2 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test2_id',
        display: 'Test 2 with id',
        data_type: 'input',
        data_option: {
          maxlength: 200,
          type: 'text',
          null: false,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_raises(RuntimeError) {
      attribute3 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test3_ids',
        display: 'Test 3 with id',
        data_type: 'input',
        data_option: {
          maxlength: 200,
          type: 'text',
          null: false,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_raises(RuntimeError) {
      attribute4 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test4',
        display: 'Test 4 with missing data_option[:type]',
        data_type: 'input',
        data_option: {
          maxlength: 200,
          null: false,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }

    attribute5 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'test5',
      display: 'Test 5',
      data_type: 'boolean',
      data_option: {
        default: true,
        options: {
          true: 'Yes',
          false: 'No',
        },
        null: false,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute5)
    assert_equal('test5', attribute5.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'test5',
    )

    assert_raises(RuntimeError) {
      attribute6 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test6',
        display: 'Test 6',
        data_type: 'boolean',
        data_option: {
          options: {
            true: 'Yes',
            false: 'No',
          },
          null: false,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }

    attribute7 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'test7',
      display: 'Test 7',
      data_type: 'select',
      data_option: {
        default: 1,
        options: {
          '1' => 'aa',
          '2' => 'bb',
        },
        null: false,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute7)
    assert_equal('test7', attribute7.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'test7',
    )

    assert_raises(RuntimeError) {
      attribute8 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test8',
        display: 'Test 8',
        data_type: 'select',
        data_option: {
          default: 1,
          null: false,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }

    attribute9 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'test9',
      display: 'Test 9',
      data_type: 'datetime',
      data_option: {
        future: true,
        past: false,
        diff: 24,
        null: true,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute9)
    assert_equal('test9', attribute9.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'test9',
    )

    assert_raises(RuntimeError) {
      attribute10 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test10',
        display: 'Test 10',
        data_type: 'datetime',
        data_option: {
          past: false,
          diff: 24,
          null: true,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }

    attribute11 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'test11',
      display: 'Test 11',
      data_type: 'date',
      data_option: {
        future: true,
        past: false,
        diff: 24,
        null: true,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute11)
    assert_equal('test11', attribute11.name)
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'test11',
    )

    assert_raises(RuntimeError) {
      attribute12 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test12',
        display: 'Test 12',
        data_type: 'date',
        data_option: {
          past: false,
          diff: 24,
          null: true,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(RuntimeError) {
      attribute13 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test13|',
        display: 'Test 13',
        data_type: 'date',
        data_option: {
          future: true,
          past: false,
          diff: 24,
          null: true,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(RuntimeError) {
      attribute14 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test14!',
        display: 'Test 14',
        data_type: 'date',
        data_option: {
          future: true,
          past: false,
          diff: 24,
          null: true,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(RuntimeError) {
      attribute15 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test15ä',
        display: 'Test 15',
        data_type: 'date',
        data_option: {
          future: true,
          past: false,
          diff: 24,
          null: true,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(RuntimeError) {
      attribute16 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test16',
        display: 'Test 16',
        data_type: 'integer',
        data_option: {
          default: 2,
          min: 1,
          max: 999,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(RuntimeError) {
      attribute17 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'test17',
        display: 'Test 17',
        data_type: 'integer',
        data_option: {
          default: 2,
          min: 1,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    assert_raises(RuntimeError) {
      attribute18 = ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'delete',
        display: 'Test 18',
        data_type: 'input',
        data_option: {
          maxlength: 200,
          type: 'text',
          null: false,
        },
        active: true,
        screens: {},
        position: 20,
        created_by_id: 1,
        updated_by_id: 1,
      )
    }
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

  end

  test 'b object manager attribute' do

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    attribute1 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'attribute1',
      display: 'Attribute 1',
      data_type: 'input',
      data_option: {
        maxlength: 200,
        type: 'text',
        null: true,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # create example ticket
    ticket1 = Ticket.create(
      title: 'some attribute test1',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      attribute1: 'some attribute text',
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert('ticket1 created', ticket1)

    assert_equal('some attribute test1', ticket1.title)
    assert_equal('Users', ticket1.group.name)
    assert_equal('new', ticket1.state.name)
    assert_equal('some attribute text', ticket1.attribute1)

    # add additional attributes
    attribute2 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'attribute2',
      display: 'Attribute 2',
      data_type: 'select',
      data_option: {
        default: '2',
        options: {
          '1' => 'aa',
          '2' => 'bb',
        },
        null: true,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    attribute3 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'attribute3',
      display: 'Attribute 3',
      data_type: 'datetime',
      data_option: {
        future: true,
        past: false,
        diff: 24,
        null: true,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    attribute4 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'attribute4',
      display: 'Attribute 4',
      data_type: 'datetime',
      data_option: {
        future: true,
        past: false,
        diff: 24,
        null: true,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )

    # execute migrations
    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert(ObjectManager::Attribute.migration_execute)
    assert_equal(false, ObjectManager::Attribute.pending_migration?)

    # create example ticket
    ticket2 = Ticket.create(
      title: 'some attribute test2',
      group: Group.lookup(name: 'Users'),
      customer_id: 2,
      state: Ticket::State.lookup(name: 'new'),
      priority: Ticket::Priority.lookup(name: '2 normal'),
      attribute1: 'some attribute text',
      attribute2: '1',
      attribute3: Time.zone.parse('2016-05-12 00:59:59 UTC'),
      attribute4: Date.parse('2016-05-11'),
      updated_by_id: 1,
      created_by_id: 1,
    )
    assert('ticket2 created', ticket2)

    assert_equal('some attribute test2', ticket2.title)
    assert_equal('Users', ticket2.group.name)
    assert_equal('new', ticket2.state.name)
    assert_equal('some attribute text', ticket2.attribute1)
    assert_equal('1', ticket2.attribute2)
    assert_equal(Time.zone.parse('2016-05-12 00:59:59 UTC'), ticket2.attribute3)
    assert_equal(Date.parse('2016-05-11'), ticket2.attribute4)

    # update data_option null -> to_config
    attribute1 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'attribute1',
      display: 'Attribute 1',
      data_type: 'input',
      data_option: {
        maxlength: 200,
        type: 'text',
        null: false,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # update data_option maxlength -> to_config && to_migrate
    attribute1 = ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'attribute1',
      display: 'Attribute 1',
      data_type: 'input',
      data_option: {
        maxlength: 250,
        type: 'text',
        null: false,
      },
      active: true,
      screens: {},
      position: 20,
      created_by_id: 1,
      updated_by_id: 1,
    )
    assert(attribute1)

    assert_equal(true, ObjectManager::Attribute.pending_migration?)
    assert_equal(1, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(1, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(1, ObjectManager::Attribute.migrations.count)

    # execute migrations
    assert(ObjectManager::Attribute.migration_execute)

    assert_equal(false, ObjectManager::Attribute.pending_migration?)
    assert_equal(0, ObjectManager::Attribute.where(to_migrate: true).count)
    assert_equal(0, ObjectManager::Attribute.where(to_config: true).count)
    assert_equal(0, ObjectManager::Attribute.migrations.count)

    # remove attribute
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'attribute1',
    )
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'attribute2',
    )
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'attribute3',
    )
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'attribute4',
    )
    assert(ObjectManager::Attribute.migration_execute)

    ticket2 = Ticket.find(ticket2.id)
    assert('ticket2 created', ticket2)

    assert_equal('some attribute test2', ticket2.title)
    assert_equal('Users', ticket2.group.name)
    assert_equal('new', ticket2.state.name)
    assert_nil(ticket2[:attribute1])
    assert_nil(ticket2[:attribute2])
    assert_nil(ticket2[:attribute3])
    assert_nil(ticket2[:attribute4])

  end

end
