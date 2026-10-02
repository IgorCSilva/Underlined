import { execSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'
import { expect, test, type Page } from '@playwright/test'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..')

function enableAccount(email: string) {
  execSync(
    `docker compose exec -T postgres psql -U underlined -d underlined_dev -c "UPDATE users SET enabled = true WHERE email = '${email}';"`,
    { cwd: repoRoot },
  )
}

function getUserId(email: string): string {
  const output = execSync(
    `docker compose exec -T postgres psql -U underlined -d underlined_dev -t -A -c "SELECT id FROM users WHERE email = '${email}';"`,
    { cwd: repoRoot },
  )
  return output.toString().trim()
}

async function signUp(page: Page, name: string, email: string, password: string) {
  await page.goto('/signup')
  await page.waitForLoadState('networkidle')
  await page.getByLabel('Name').fill(name)
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Sign up' }).click()
  await expect(page.getByText(/will send you an email to confirm/)).toBeVisible()

  enableAccount(email)
}

async function logIn(page: Page, email: string, password: string) {
  await page.getByRole('link', { name: 'Back to log in' }).click()
  await page.getByLabel('Email').fill(email)
  await page.getByLabel('Password').fill(password)
  await page.getByRole('button', { name: 'Log in' }).click()
  await expect(page).toHaveURL('/profile')
}

test('following and unfollowing a user updates the button and the Following feed', async ({ page }) => {
  const unique = Date.now()
  const authorEmail = `e2e-follow-author-${unique}@example.com`
  const readerEmail = `e2e-follow-reader-${unique}@example.com`
  const password = 'supersecret1'
  const title = `Follow Test Book ${unique}`
  const bookAuthor = `Book Author ${unique}`
  const passage = `A passage worth following ${unique}.`
  const thinking = `This made me think about things ${unique}.`

  await signUp(page, 'Follow Author', authorEmail, password)
  await logIn(page, authorEmail, password)

  await page.goto('/books/new')
  await page.getByLabel('Title').fill(title)
  await page.getByLabel('Author').fill(bookAuthor)
  await page.getByRole('button', { name: 'Add book' }).click()
  await expect(page).toHaveURL('/books')

  await page.getByText(title).click()
  await expect(page).toHaveURL(/\/posts\/new\?bookId=/)

  await page.getByLabel('The passage').fill(passage)
  await page.getByLabel('What I think about it').fill(thinking)
  await page.getByRole('button', { name: 'Publish' }).click()
  await expect(page.getByText('Published!')).toBeVisible()

  const authorId = getUserId(authorEmail)

  await page.goto('/profile')
  await page.getByRole('button', { name: 'Log out' }).click()

  await signUp(page, 'Follow Reader', readerEmail, password)
  await logIn(page, readerEmail, password)

  await page.goto(`/profile/${authorId}`)
  const followButton = page.getByRole('button', { name: 'Follow', exact: true })
  await expect(followButton).toBeVisible()

  await followButton.click()
  await expect(page.getByRole('button', { name: 'Following' })).toBeVisible()

  await page.reload()
  await page.waitForLoadState('networkidle')
  await expect(page.getByRole('button', { name: 'Following' })).toBeVisible()

  await page.goto('/feed')
  await page.getByRole('tab', { name: 'Following' }).click()
  await expect(page.getByText(passage)).toBeVisible()

  await page.goto(`/profile/${authorId}`)
  await page.getByRole('button', { name: 'Following' }).click()
  await expect(followButton).toBeVisible()

  await page.goto('/feed')
  await page.getByRole('tab', { name: 'Following' }).click()
  await expect(page.getByText('No posts yet from people you follow.')).toBeVisible()
})
