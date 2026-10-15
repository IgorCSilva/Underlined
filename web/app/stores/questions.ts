import type { Book } from '~/stores/books'

export interface Question {
  id: string
  body: string
  answer_count: number
  inserted_at: string
  book: Book
  passage: { id: string; text: string }
  user: { id: string; name: string; avatar_url: string | null }
}

export interface Answer {
  id: string
  question_id: string
  body: string
  best: boolean
  inserted_at: string
  user: { id: string; name: string; avatar_url: string | null }
}

interface QuestionResponse {
  data: Question
}

interface AnswerResponse {
  data: Answer
}

interface AnswerListResponse {
  data: Answer[]
}

export const useQuestionsStore = defineStore('questions', {
  actions: {
    async createQuestion(bookId: string, payload: { passage_text: string; body: string }): Promise<Question> {
      const { request } = useApi()
      const res = await request<QuestionResponse>(`/api/books/${bookId}/questions`, {
        method: 'POST',
        body: { question: payload },
      })
      return res.data
    },

    async listAnswers(questionId: string): Promise<Answer[]> {
      const { request } = useApi()
      const res = await request<AnswerListResponse>(`/api/questions/${questionId}/answers`)
      return res.data
    },

    async createAnswer(questionId: string, payload: { body: string }): Promise<Answer> {
      const { request } = useApi()
      const res = await request<AnswerResponse>(`/api/questions/${questionId}/answers`, {
        method: 'POST',
        body: { answer: payload },
      })
      return res.data
    },

    async markBestAnswer(answerId: string): Promise<Answer> {
      const { request } = useApi()
      const res = await request<AnswerResponse>(`/api/answers/${answerId}/best`, { method: 'PUT' })
      return res.data
    },
  },
})
