import HomeStyle from './page.module.css'

export default function App() {
    return (
        <div className={HomeStyle.HomeContainer}>
            <nav>
                <h1>V Farm</h1>
                <ul>
                    <a href="">Home</a>
                    <a href="">Features</a>
                    <a href="">About</a>
                    <a href="">How it works ?</a>
                </ul>
                <a href="">Download <i className="bx bx-arrow-to-bottom" /></a>
            </nav>
            <section className={HomeStyle.Home}>

            </section>
        </div>
    )
}