# Family Feature Documentation

## Overview

The Family feature allows users to create families, invite members via email, and share cookbooks containing recipes. This feature enables collaborative recipe management where family members can add, edit, and organize recipes together.

## Key Components

### Models

#### Family
- **Purpose**: Represents a family group with members and cookbooks
- **Key Attributes**:
  - `name` - Family name (required)
  - `description` - Optional description 
  - `slug` - Auto-generated URL-friendly identifier
  - `creator_id` - References the user who created the family
- **Relationships**:
  - `belongs_to :creator` (User)
  - `has_many :family_memberships`
  - `has_many :members` (through memberships)
  - `has_many :cookbooks`
  - `has_one :default_cookbook`
- **Key Methods**:
  - `member?(user)` - Check if user is a family member
  - `can_manage?(user)` - Check if user can manage the family (creator only)
  - `pending_invitation_for?(user)` - Check for pending invitations

#### FamilyMembership
- **Purpose**: Join table managing family membership and invitations
- **Key Attributes**:
  - `family_id`, `user_id` - Foreign keys
  - `status` - Enum: pending, accepted, declined
  - `invitation_token` - Unique token for email invitations
  - `invited_at`, `accepted_at` - Timestamps
- **Key Methods**:
  - `accept!` - Accept invitation
  - `decline!` - Decline invitation
  - `expired?` - Check if invitation is expired (30 days)

#### Cookbook
- **Purpose**: Collection of recipes within a family
- **Key Attributes**:
  - `name` - Cookbook name (required)
  - `description` - Optional description
  - `family_id` - Foreign key to family
  - `is_default` - Boolean flag for default cookbook
  - `slug` - Auto-generated URL-friendly identifier
- **Key Methods**:
  - `accessible_by?(user)` - Check if user can access cookbook
  - `editable_by?(user)` - Check if user can edit recipes
  - `can_manage?(user)` - Check if user can manage cookbook settings

### Controllers

#### FamiliesController
- **Actions**: index, show, new, create, edit, update, destroy
- **Authorization**: Requires user authentication, creator-only for management actions
- **Key Features**:
  - Lists user's families
  - Shows family overview with cookbooks and recent recipes
  - CRUD operations for families

#### Families::MembershipsController
- **Actions**: index, create, destroy, accept, decline
- **Key Features**:
  - Manage family members
  - Send email invitations
  - Handle invitation acceptance/decline via email links
  - Remove members (creator only)

#### CookbooksController
- **Actions**: index, show, new, create, edit, update, destroy
- **Authorization**: Family members can view, creator can manage
- **Key Features**:
  - List family cookbooks
  - Show cookbook with paginated recipes
  - CRUD operations for cookbooks

#### Cookbooks::RecipesController
- **Actions**: index, show, new, create, edit, update, destroy
- **Authorization**: Family members can CRUD recipes, authors can edit their own
- **Key Features**:
  - Manage recipes within cookbooks
  - Recipe author or family creator can edit/delete

#### Profiles::FamiliesController
- **Actions**: index
- **Key Features**: "My Families" dashboard showing all user's families and pending invitations

### Email System

#### FamilyMailer
- **Purpose**: Send family invitation emails
- **Templates**: HTML and text versions
- **Features**:
  - Professional email design
  - Accept/decline buttons linking to invitation handlers
  - Family information and invitation details

## User Permissions

### Family Creator
- Create/edit/delete family
- Create/edit/delete cookbooks (except default cookbook name)
- Invite/remove members
- Edit/delete any recipes in family cookbooks

### Family Members
- View family and cookbooks
- Add recipes to any family cookbook
- Edit/delete their own recipes
- Accept/decline invitations

### Non-Members
- No access to family content
- Can only accept/decline invitations via email links

## Database Schema

```sql
-- Families table
CREATE TABLE families (
  id INTEGER PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  creator_id INTEGER NOT NULL,
  slug VARCHAR UNIQUE,
  created_at DATETIME,
  updated_at DATETIME,
  FOREIGN KEY (creator_id) REFERENCES users(id)
);

-- Family memberships table
CREATE TABLE family_memberships (
  id INTEGER PRIMARY KEY,
  family_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  status INTEGER DEFAULT 0 NOT NULL,
  invitation_token VARCHAR UNIQUE,
  invited_at DATETIME,
  accepted_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  FOREIGN KEY (family_id) REFERENCES families(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE(family_id, user_id)
);

-- Cookbooks table
CREATE TABLE cookbooks (
  id INTEGER PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  family_id INTEGER NOT NULL,
  is_default BOOLEAN DEFAULT FALSE,
  slug VARCHAR,
  created_at DATETIME,
  updated_at DATETIME,
  FOREIGN KEY (family_id) REFERENCES families(id),
  UNIQUE(family_id, slug)
);

-- Updated recipes table
ALTER TABLE recipes ADD COLUMN cookbook_id INTEGER;
ALTER TABLE recipes ADD FOREIGN KEY (cookbook_id) REFERENCES cookbooks(id);
```

## Routes

```ruby
# Family routes
resources :families, param: :slug do
  namespace :families do
    resources :memberships, only: [:index, :create, :destroy]
  end
  resources :cookbooks, param: :slug do
    namespace :cookbooks do
      resources :recipes, param: :slug
    end
  end
end

# Family invitation routes
get '/family_invitations/:token/accept', to: 'families/memberships#accept'
get '/family_invitations/:token/decline', to: 'families/memberships#decline'

# Profile routes
namespace :profiles do
  resources :families, only: [:index]
end
```

## Views Structure

```
app/views/
├── families/
│   ├── index.html.erb          # List user's families
│   ├── show.html.erb           # Family overview
│   ├── new.html.erb            # Create family form
│   ├── edit.html.erb           # Edit family form
│   └── memberships/
│       └── index.html.erb      # Manage members
├── cookbooks/
│   ├── index.html.erb          # List family cookbooks
│   ├── show.html.erb           # Cookbook with recipes
│   ├── new.html.erb            # Create cookbook form
│   ├── edit.html.erb           # Edit cookbook form
│   └── recipes/
│       ├── index.html.erb      # List cookbook recipes
│       ├── show.html.erb       # Recipe details
│       ├── new.html.erb        # Add recipe form
│       └── edit.html.erb       # Edit recipe form
├── profiles/
│   └── families/
│       └── index.html.erb      # My Families dashboard
└── family_mailer/
    ├── invitation.html.erb     # HTML email template
    └── invitation.text.erb     # Text email template
```

## Key Features

### Automatic Setup
- Default "Family Recipes" cookbook created automatically
- Family creator automatically added as accepted member
- Slug generation for SEO-friendly URLs

### Email Invitations
- Professional email templates
- 30-day expiration for security
- One-click accept/decline from email
- Invitation status tracking

### Access Control
- Robust authorization system
- Family-scoped cookbook access
- Recipe editing permissions
- Creator-only management features

### User Experience
- "My Families" dashboard
- Pending invitations display
- Breadcrumb navigation
- Responsive design with Tailwind CSS

## Testing

Comprehensive test coverage includes:
- Model validations and relationships
- Controller authorization
- Email delivery
- Invitation workflow
- Access control scenarios

## Installation/Migration

1. Run migrations: `rails db:migrate`
2. Seed test data (optional): `rails db:seed`
3. Configure email settings for invitations
4. Update navigation to include "My Families" link

## Usage Examples

### Creating a Family
1. Navigate to "My Families" from account menu
2. Click "Create New Family"
3. Fill in family name and description
4. Default cookbook is automatically created

### Inviting Members
1. Go to family page → "Manage Members"
2. Enter member's email address
3. System sends invitation email
4. Member clicks accept/decline in email

### Managing Cookbooks
1. Family creator can create additional cookbooks
2. All members can add recipes to any cookbook
3. Only recipe authors and family creator can edit recipes
4. Default cookbook cannot be deleted

This feature provides a complete collaborative recipe management system for families while maintaining proper security and user experience.