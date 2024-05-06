// drizzle db schema 

import { serial, integer, text, timestamp, json, pgTable } from 'drizzle-orm/pg-core';

export const userTable = pgTable('user', {
  id: serial('id').primaryKey(),
  email: text('email').unique(),
  password: text('password'),
  createdAt: timestamp('createdAt').defaultNow().notNull(),
});

export const carTable = pgTable('car', {
  id: serial('id').primaryKey(),
  vin: text('vin').unique(),
  brand: text('brand'),
  createdAt: timestamp('createdAt').defaultNow().notNull(),
  notes: json('notes'),
  DeletedAt : timestamp('deletedAt').defaultNow().notNull(),
  StatusTypeCode: integer('StatusTypeCode'),
});


export const ErrorLogTable = pgTable('errorLog', {
  id: serial('id').primaryKey(),
  createdAt: timestamp('createdAt').defaultNow().notNull(),
  value: text('value'),
  errorCode: integer('errorCode'),
  notes: json('notes'),
  DeletedAt : timestamp('deletedAt').defaultNow().notNull(),
});

export const mileageTable = pgTable('mileageEntries', {
  id: serial('id').primaryKey(),
  car: text('vin').references(()=>carTable.vin),
  createdAt: timestamp('createdAt').defaultNow().notNull(),
  value: text('value'),
  dataProvider: text('value'),
  errorId: serial('errorId').references(()=>ErrorLogTable.id),
});